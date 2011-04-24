class Bet < ActiveRecord::Base
  acts_as_content
  acts_as_categorizable

  TOP_BET_WINNERS = "#{RAILS_ROOT}/public/storage/apuestas/top_bets_winners_minicolumns_data"
  OPEN_BETS_SQL = "closes_on > now() AND winning_bets_option_id IS NULL AND tie is false AND cancelled is false AND forfeit is false"
  AWAITING_RESULT_SQL = "closes_on < now() and winning_bets_option_id is null and tie is false and cancelled is false and forfeit is false"
  CLOSED_BETS_SQL = "closes_on < now() and (winning_bets_option_id is not null or tie is true or cancelled is true or forfeit is true)"


  after_save :process_bets_options
  has_many :bets_options, :dependent => :destroy

  named_scope :awaiting_result, :conditions => Bet::AWAITING_RESULT_SQL,
                                :order => 'closes_on DESC, id DESC'

  named_scope :closed_bets, :conditions => Bet::CLOSED_BETS_SQL,
                            :order => 'closes_on DESC, id DESC'

  named_scope :open_bets, :conditions => Bet::OPEN_BETS_SQL,
                          :order => 'closes_on ASC, id ASC'

  observe_attr :winning_bets_option_id, :cancelled, :forfeit, :tie


  def self.earnings(user, limit=30, time_window=nil)
    # Returns a user earnings during a time window.
    #
    # Args:
    #   user: the user to calculate earnings for.
    #   limit: the maximum number of bets to consider.
    #   time_window: an SQL-compatible time interval definition. Eg: '7 days'
    #
    # Returns:
    #   An array of earnings per bet sorted by bet closing time.
    where_sql = time_window ? " AND bet_id in (SELECT id FROM bets WHERE closes_on >= now() - '#{time_limit_sql_interval}'::interval)" : ''
    db_query("SELECT net_ammount
                FROM stats.bets_results
               WHERE user_id = #{user.id}
                #{where_sql}
            ORDER BY (SELECT closes_on FROM bets WHERE id = bet_id) DESC
               LIMIT #{limit}").collect do |dbr|
      dbr['net_ammount'].to_i * (-1)
     end
  end

  def self.top_earners(time_window=nil)
    where_sql = time_window ? " AND closes_on >= now() - '#{time_limit_sql_interval}'::interval" : ''
    db_query("SELECT user_id,
                     sum(net_ammount)
                FROM stats.bets_results
               WHERE bet_id IN (select id
                                 from bets
                                 where state = #{Cms::PUBLISHED}
                                  AND (winning_bets_option_id IS NOT NULL
                                   or forfeit = 't'
                                   or cancelled = 't'
                                   or tie = 't')
                                   #{where_sql})
               group by user_id order by sum(net_ammount) ASC LIMIT 10").collect do |dbr|
      [User.find(dbr['user_id'].to_i), dbr['sum']]
    end
  end

  def options_new=(opts_new)
    @_tmp_options_new = opts_new
    self.attributes.delete :options_new
  end

  def options_delete=(opts_new)
    @_tmp_options_delete = opts_new
    self.attributes.delete :options_delete
  end

  def options=(opts_new)
    @_tmp_options = opts_new
    self.attributes.delete :options
  end

  def earnings(user)
    db_query("SELECT net_ammount
                FROM stats.bets_results
               WHERE user_id = #{user.id}
                 AND bet_id = #{self.id}")[0]['net_ammount'].to_i * (-1)
  end

  def users
    # Returns users who have placed bets in this bet.
    User.find(:all, :conditions => "id IN (
        SELECT distinct(user_id) as user_id
          FROM bets_tickets
         WHERE bets_option_id IN (SELECT id
                                    FROM bets_options
                                   WHERE bet_id = #{self.id}))")
  end

  def completed?
    (self.winning_bets_option_id != nil) || self.cancelled || self.forfeit || self.tie
  end

  def reopen
    # Reopens a closed bet.
    #
    # This only works if the bet's title isn't changed since the bet was closed because
    # we depend on it to revert cash movements.
    raise "Bet unclosed" unless self.can_be_reopened?
    self.update_attributes({ :winning_bets_option_id => nil,
                             :cancelled => false,
                             :forfeit => false,
                             :tie => false})

    CashMovement.find(:all, :conditions => "description like 'Ganancias %\"#{title.gsub('"', '\\"')}\"'").each do |cm|
      Bank.revert_transfer(cm)
    end

    User.db_query("DELETE FROM stats.bets_results WHERE bet_id = #{self.id}")
  end

  def can_be_reopened?
    self.completed? && self.state == Cms::PUBLISHED # && self.closes_on > 2.weeks.ago
  end

  def complete(winning_bets_option_id)
    self.reload
    return if self.completed?
    current_total_amount = BetsOption.sum(:ammount,
                                          :conditions => ['bet_id = ?', self.id]).to_f
    self.update_attribute(:total_ammount, current_total_amount)

    if winning_bets_option_id == 'cancelled' then
      self.return_bet_money
      self.cancelled = true
    elsif winning_bets_option_id == 'tie' then
      self.resolve_tie
      self.tie = true
    elsif winning_bets_option_id == 'forfeit' then
      self.return_bet_money
      self.forfeit = true
    else # standard
      # aseguramos de que la opción dada es correcta
      self.bets_options.find(winning_bets_option_id) # esto lanzará un error si no se encuentra la opción
      self.winning_bets_option_id = winning_bets_option_id
      # hacemos la distribución de dinero de los bandos perdedores entre los ganadores
      # calculamos la suma a distribuir de las opciones que no han sido la ganadora

      # comprobamos que en la apuesta haya más de una persona
      _users = self.users
      users_total = _users.size
      if users_total == 0 then
        # do nothing
      elsif users_total == 1 then
        u = _users[0]
        # si solo ha participado una persona le devolvemos el dinero
        # TODO copypaste
        cash_previous = db_query("SELECT COALESCE(sum(ammount), 0) as ammount from bets_tickets where bets_option_id IN (SELECT id FROM bets_options WHERE bet_id = #{self.id}) and user_id = #{u.id}")[0]['ammount'].to_f
        if cash_previous > 0 then
          Bank.transfer(:bank, u, cash_previous, "Solo tú participaste en la apuesta \"#{self.resolve_hid}\"")
        end
      else
        # No usamos total_ammount porque lo que queremos es repartir el dinero de la opción que NO ha ganado
        sum = db_query("SELECT COALESCE(sum(ammount), 0) as ammount from bets_options where bet_id = #{self.id} and id <> #{self.winning_bets_option_id}")[0]['ammount'].to_f
        if sum > 0 then
          # calculamos porcentajes de la gente que ha apostado por la opción
          # ganadora
          bopt = BetsOption.find(winning_bets_option_id)
          self.winning_bets_option_id = winning_bets_option_id
          total = bopt.ammount

          for ticket in bopt.bets_tickets # un ticket por persona
            new_cash = (ticket.ammount / total) * sum + ticket.ammount # le devolvemos lo que apostó por esta opción además del porcentaje del resto de opciones
            if new_cash > 0 then
              u = ticket.user
              Bank.transfer(:bank, u, new_cash, "Ganancias por tu apuesta por \"#{self.resolve_hid}\"")
            end
          end
        end
      end # if users.length < 2
    end

    calculate_earnings
    self.save
  end

  protected
  def process_bets_options
    if @_tmp_options_new
      @_tmp_options_new.each { |s| self.bets_options.create({:name => s.strip}) unless s.strip == '' }
      @_tmp_options_new = nil
    end

    if @_tmp_options_delete
      @_tmp_options_delete.each { |id| self.bets_options.find(id).destroy if self.bets_options.find_by_id(id) }
      @_tmp_options_delete = nil
    end

    if @_tmp_options
      @_tmp_options.keys.each do |id|
        option = self.bets_options.find_by_id(id.to_i)
        if option && option.name != @_tmp_options[id]
          option.name = @_tmp_options[id].strip
          option.save
        end
      end
      @_tmp_options = nil
    end
    true
  end

  def resolve_tie
    money_to_give = {}
    percentages = {}
    total_money = self.total_ammount

    opt1 = self.bets_options[0]
    opt2 = self.bets_options[1]
    sphase_points = {}
    money_bet = {}

    for u in self.users
      op1 = user_amount_in_option(u, opt1)
      op2 = user_amount_in_option(u, opt2)
      money_bet[u.id] = op1 + op2

      if op1 == 0 and op2 == 0
        next
      elsif op1 == 0
        pcent = 0.01
      elsif op2 == 0
        pcent = 0.01
      else
        if op1/op2 > op2/op1
          pcent = op2/op1
        else
          pcent = op1/op2
        end
      end

      percentages[u.id] = pcent
      money_to_give[u.id] = pcent * (op1 + op2)
      total_money -= money_to_give[u.id]
      sphase_points[u.id] = money_to_give[u.id]
    end

    # ya tenemos los porcentajes y el dinero a repartir
    pcents = []
    percentages.each_value { |b| pcents<< b } # pasamos porcentajes a array
    stddev = Math.standard_deviation(pcents)
    if stddev == 0 # no ha habido desviación, nadie ganará nada
      for u in self.users
        op1 = user_amount_in_option(u, opt1)
        op2 = user_amount_in_option(u, opt2)

        if op1 + op2 > 0
          Bank.transfer(:bank, u, op1 + op2, "Ganancias por tu apuesta por \"#{self.resolve_hid}\"")
        end
      end
    else
      # del bote restante (gmfs de fallos) cada uno se lleva una parte
      # correspondiente a sus puntos calculados en primera fase
      losers_money = total_money
      total_points = money_to_give.values.sum.to_f

      self.users.each do |u|
        next if sphase_points[u.id].to_i == 0
        money_to_give[u.id] +=  money_to_give[u.id] / total_points * losers_money
      end

      money_to_give.keys.each do |k|
        Bank.transfer(:bank, User.find(k), money_to_give[k], "Ganancias por tu apuesta por \"#{self.resolve_hid}\"") if money_to_give[k] > 0
      end
    end # end if stddev == 1.0
  end

  def return_bet_money
    return if self.completed?
    self.users.each do |user|
      cash_previous = User.db_query("SELECT COALESCE(sum(ammount), 0) as ammount
                                       FROM bets_tickets
                                      WHERE bets_option_id IN (SELECT id
                                                                 FROM bets_options
                                                                WHERE bet_id = #{self.id})
                                                                  AND user_id = #{user.id}")[0]['ammount'].to_f
      if cash_previous > 0
        Bank.transfer(:bank, user, cash_previous,
                      "Apuestas para partida \"#{self.resolve_hid}\" canceladas")
      end
    end
  end

  def calculate_earnings
    users.each do |u|
      if self.cancelled? || self.forfeit? || users.size == 1
        net_ammount = 0
      else
        cash_bet = db_query("SELECT COALESCE(sum(ammount), 0) as ammount from bets_tickets where bets_option_id IN (SELECT id FROM bets_options WHERE bet_id = #{self.id}) and user_id = #{u.id}")[0]['ammount'].to_f
        description = "Ganancias por tu apuesta por \"#{self.resolve_hid}\""
        dbcg = db_query("SELECT ammount from cash_movements WHERE object_id_to_class = 'User' AND object_id_to = #{u.id} AND description = #{User.connection.quote(description)}")
        cash_returned = dbcg.size > 0 ? dbcg[0]['ammount'].to_f : 0
        net_ammount = cash_bet - cash_returned
      end
      db_query("INSERT INTO stats.bets_results(bet_id, user_id, net_ammount) VALUES(#{self.id}, #{u.id}, #{net_ammount})")
    end
  end

  def user_amount_in_option(user, bets_option)
    # Returns the amount bet by a user in a given option.
    db_query("SELECT COALESCE(sum(ammount), 0) as ammount
                FROM bets_tickets
               WHERE bets_option_id = #{bets_option.id}
                 AND user_id = #{user.id}")[0]['ammount'].to_f
  end
end
