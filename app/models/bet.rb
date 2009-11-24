class Bet < ActiveRecord::Base
  acts_as_content
  acts_as_categorizable
  
  #before_save :check_options_new
  TOP_BET_WINNERS = "#{RAILS_ROOT}/public/storage/apuestas/top_bets_winners_minicolumns_data"
  OPEN_BETS_SQL = "closes_on > now() AND winning_bets_option_id IS NULL AND tie is false AND cancelled is false AND forfeit is false"
  AWAITING_RESULT_SQL = "closes_on < now() and winning_bets_option_id is null and tie is false and cancelled is false and forfeit is false"
  CLOSED_BETS_SQL = "closes_on < now() and (winning_bets_option_id is not null or tie is true or cancelled is true or forfeit is true)"
  
  after_save :process_bets_options
  has_many :bets_options, :dependent => :destroy
  
  validates_uniqueness_of :title, :message => 'Ya hay otra apuesta con el mismo título'
  
  observe_attr :winning_bets_option_id, :cancelled, :forfeit, :tie
  
  #def total_ammount
  #  ammount = self.class.db_query("SELECT COALESCE(sum(ammount), 0) as ammount from bets_options where bet_id = #{self.id}")[0]['ammount'].to_f
  #end
  
  def options_new=(opts_new)
    @_tmp_options_new = opts_new
    self.attributes.delete :options_new 
  end


  def closed?
    self.closes_on < Time.now && (!self.winning_bets_option_id.nil? || self.tie == true || self.cancelled == true || self.forfeit == true)
  end
  
  def options_delete=(opts_new)
    @_tmp_options_delete = opts_new
    self.attributes.delete :options_delete 
  end
  
  def options=(opts_new)
    @_tmp_options = opts_new
    self.attributes.delete :options 
  end
  
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
  
  def self.top_winners(time_limit_sql_interval='')    
    where_sql = time_limit_sql_interval != '' ? " AND closes_on >= now() - '#{time_limit_sql_interval}'::interval" : ''

    db_query("select user_id, 
                     sum(net_ammount) 
                from stats.bets_results
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
  
  def self.net_wins(user, limit=30, time_limit_sql_interval=nil)
    # Devuelve un array de ganancias/perdidas del usuario en las ultimas 30 apuestas en las que ha participado ordenadas de mas reciente a menos
    results = []
    where_sql = time_limit_sql_interval.to_s != '' ? " AND bet_id in (select id from bets where closes_on >= now() - '#{time_limit_sql_interval}'::interval)" : ''
    db_query("SELECT net_ammount 
                FROM stats.bets_results 
               WHERE user_id = #{user.id}
                #{where_sql} 
            ORDER BY (select closes_on from bets where id = bet_id) DESC 
               LIMIT #{limit}").each do |dbr|
      results<< dbr['net_ammount'].to_i * (-1) # los net ammounts son negativos si gana                                                 
     end
     results
  end
  
  def net_win(user)
    db_query("SELECT net_ammount 
                FROM stats.bets_results 
               WHERE user_id = #{user.id}
                 AND bet_id = #{self.id}")[0]['net_ammount'].to_i * (-1)
  end

  def return_money_to_users
    return if self.completed? 
    
    # devuelve el dinero apostado a los usuarios
    dbusers = self.class.db_query("SELECT distinct(user_id) as user_id from bets_tickets where bets_option_id IN (SELECT id from bets_options where bet_id = #{self.id})")
    for dbuser in dbusers
      cash_previous = User.db_query("SELECT COALESCE(sum(ammount), 0) as ammount from bets_tickets where bets_option_id IN (SELECT id FROM bets_options WHERE bet_id = #{self.id}) and user_id = #{dbuser['user_id']}")[0]['ammount'].to_f
      if cash_previous > 0
        Bank.transfer(:bank, User.find(dbuser['user_id'].to_i), cash_previous, "Apuestas para partida \"#{self.resolve_hid}\" canceladas")
      end
    end
  end
  
  def users
    User.find(:all, :conditions => "id IN (SELECT distinct(user_id) as user_id from bets_tickets where bets_option_id IN (SELECT id from bets_options where bet_id = #{self.id}))")
  end
  
  
  
  def completed?
    self.winning_bets_option_id != nil || self.cancelled || self.forfeit || self.tie
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
      op1 = ammount_bet_by_user_in_option(u, opt1)
      op2 = ammount_bet_by_user_in_option(u, opt2)
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
      #puts "#{u.id} pcent: #{pcent} op1: #{op1} op2: #{op2} money_to_give: #{money_to_give[u.id]} total_money: #{total_money}"
    end
    
    # ya tenemos los porcentajes y el dinero a repartir
    pcents = []
    percentages.each_value { |b| pcents<< b } # pasamos porcentajes a array
    stddev = Math.standard_deviation(pcents)
    if stddev == 0 # no ha habido desviación, nadie ganará nada
      for u in self.users
        op1 = ammount_bet_by_user_in_option(u, opt1)
        op2 = ammount_bet_by_user_in_option(u, opt2)
        
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
#       puts "#{k}\t#{(percentages[k] * 100).to_i.to_f / 100}\t #{(money_to_give[k] * 100).to_i.to_f / 100}\t #{(sphase_points[k] * 100).to_i.to_f / 100}"
# puts "Resolución por tu apuesta en\"#{self.resolve_hid}\": \"#{((money_to_give[k] - money_bet[k])* 100).to_i.to_f / 100}\""
        Bank.transfer(:bank, User.find(k), money_to_give[k], "Ganancias por tu apuesta por \"#{self.resolve_hid}\"") if money_to_give[k] > 0 
        # Bank.transfer(:bank, User.find(k), money_to_give[k], "Ganancias por tu apuesta por \"#{self.resolve_hid}\": \"#{((money_to_give[k] - money_bet[k])* 100).to_i.to_f / 100}\"") if money_to_give[k] > 0 
      end
    end # end if stddev == 1.0
  end
  
  # TODO limitar apuestas a 2 opciones para que este algoritmo funcione.
  # En caso de empate hacemos una primera vuelta en la que:
  # - calculamos el porcentaje entre lo apostado por una opción y lo apostado
  #   por otra
  #
  # - devolvemos a cada jugador: apostado * [ op1/op2 ó op2/op1 ]. De esta
  #   forma los que más equilibradas hayan hecho sus apuestas más recuperan.
  #   Vamos acumulando el dinero sobrante en una variable temporal
  #
  #
  # Ahora que sabemos el porcentaje de balance entre una opción y otra de cada
  # jugador calculamos la desviación estandard de todos los porcentajes y
  # empezamos a repatir a cada jugador empezando por el más equilibrado y
  # acabando por el menos equilibrado desviación_std_de_porcentajes * cantidad
  # que queda por repartir. Cuando se acabe el dinero por repartir hemos
  # acabado de dar el dinero. Hacemos las transferencias y listo.
  def resolve_tieOLD
    money_to_give = {}
    percentages = {}
    total_money = self.total_ammount
    
    opt1 = self.bets_options[0]
    opt2 = self.bets_options[1]
    
    for u in self.users
      op1 = ammount_bet_by_user_in_option(u, opt1)
      op2 = ammount_bet_by_user_in_option(u, opt2)
      
      if op1 == 0 and op2 == 0
        next
      elsif op1 == 0
        pcent = 0.0
      elsif op2 == 0
        pcent = 0.0
      else
        if op1/op2 > op2/op1
          pcent = op2/op1
        else
          pcent = op1/op2
        end
      end
      
      # Nos aseguramos de que cogemos el porcentaje menor siempre
      
      percentages[u.id] = pcent
      money_to_give[u.id] = pcent * (op1 + op2)
      total_money -= money_to_give[u.id]
      #puts "#{u.id} pcent: #{pcent} op1: #{op1} op2: #{op2} money_to_give: #{money_to_give[u.id]} total_money: #{total_money}"
    end
    
    # ya tenemos los porcentajes y el dinero a repartir
    pcents = []
    percentages.each_value { |b| pcents<< b } # pasamos porcentajes a array
    stddev = Math.standard_deviation(pcents)
    if stddev == 0 # no ha habido desviación, nadie ganará nada
      for u in self.users
        op1 = ammount_bet_by_user_in_option(u, opt1)
        op2 = ammount_bet_by_user_in_option(u, opt2)
        
        if op1 + op2 > 0
          Bank.transfer(:bank, u, op1 + op2, "Ganancias por tu apuesta por \"#{self.resolve_hid}\"")
        end
      end
    else
      # Agrupamos por porcentajes como claves y users en array para repartir lo
      # mismo a todos los usuarios con un mismo porcentaje:
      u_grouped_by_pcent = {}
      percentages.each do |k, v|
        u_grouped_by_pcent[v] ||= []
        u_grouped_by_pcent[v]<< k
      end
      
      # Bucle de repartor dle dinero sobrante
      while total_money > 0.01 # usamos 0.01 para evitar entrar en un bucle infinito
        u_left = u_grouped_by_pcent.clone
        subpart = 1
        prev_subpart = -1 # la ponemos aquí a propósito, si hay muchos usuarios
        # con porcentaje 0.0 y pocos con porcentaje 1.0 les daremos un repartor más
        # a los de porcentaje 1.0 que a los de 0.0
        # puts 'foo'
        while total_money > 0.01 && u_left.size > 0 && subpart > 0.01
          u_cur = u_left[u_left.keys.pop]
          u_left.delete(u_left.keys.pop)
          ammount_this_round = total_money * stddev
          subpart = ammount_this_round / u_cur.size
          if prev_subpart > -1 && subpart > prev_subpart then
            subpart = prev_subpart
          end
          total_money -= subpart * u_cur.size # lo ponemos aquí porque no
          # queremos repartir más a un usuario individual que tenga porcentaje 0.0
          # que a 5 que tengan porcentaje 1.0
          if subpart > 0.01 # solo añadimos si no estamos añadiendo menos de un céntimo de GMF
            u_cur.each { |user_id| money_to_give[user_id] += subpart }
          end
          # puts "subpart: #{subpart} | #{u_cur.size} | #{ammount_this_round} | total_money: #{total_money}"
          prev_subpart = subpart
        end
      end
      
      #while total_money > 0
      #  u_left = sorted_users_in_this_bet_by_percentages.clone # el último es el de mayor porcentaje
      #  while total_money > 0 && u_left.size > 0
      #    u = User.find(u_left.pop[0])
      #    money_to_give[u.id] += total_money * stddev
      #    total_money -= money_to_give[u.id]
      #  end
      #end
      
      # puts "MONEY TO GIVE"
      for k in money_to_give.keys
        # puts "#{k}: #{money_to_give[k]}"
        Bank.transfer(:bank, User.find(k), money_to_give[k], "Ganancias por tu apuesta por \"#{self.resolve_hid}\"") if money_to_give[k] > 0 
      end
    end # end if stddev == 1.0
  end

  def awards_breakdown
    dbusers = self.class.db_query("SELECT distinct(user_id) as user_id from bets_tickets where bets_option_id IN (SELECT id from bets_options where bet_id = #{self.id})")
    bdw = []
    ba = self.bets_options.find(:first, :order => 'id')
    bb = self.bets_options.find(:first, :order => 'id DESC')
    dbusers.each do |dbu|
      u = User.find(dbu['user_id'].to_i)
	      bdw <<  {:user => u, :team1 => self.ammount_bet_by_user_in_option(u, ba), :team2 => self.ammount_bet_by_user_in_option(u, bb), :net => self.net_win(u) }
    end
    bdw 
  end
  
  def ammount_bet_by_user_in_option(user, bets_option)
    db_query("SELECT COALESCE(sum(ammount), 0) as ammount 
                FROM bets_tickets 
               WHERE bets_option_id = #{bets_option.id} 
                 AND user_id = #{user.id}")[0]['ammount'].to_f
  end
  
  # reabre una apuesta cerrada
  # TODO: hay que hacer tests para esto
  def reopen
    # Esto solo funciona si no se cambia el título de la apuesta desde el momento que se reparten las ganancias al momento de revertirlas
    raise "Bet unclosed" unless self.can_be_reopened?
    self.winning_bets_option_id = nil
    self.cancelled = false
    self.forfeit = false
    self.tie = false
    self.save
    
    # TODO no escapamos el title
    CashMovement.find(:all, :conditions => "description like 'Ganancias %\"#{title}\"'").each do |cm|
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
    
    if winning_bets_option_id == 'cancelled' then
      self.return_money_to_users
      self.cancelled = true
    elsif winning_bets_option_id == 'tie' then
      self.resolve_tie
      self.tie = true
    elsif winning_bets_option_id == 'forfeit' then
      self.return_money_to_users
      self.forfeit = true
    else # standard
      # aseguramos de que la opción dada es correcta
      self.bets_options.find(winning_bets_option_id) # esto lanzará un error si no se encuentra la opción
      self.winning_bets_option_id = winning_bets_option_id
      # hacemos la distribución de dinero de los bandos perdedores entre los
      # ganadores
      # calculamos la suma a distribuir de las opciones que no han sido la
      # ganadora
      
      
      # comprobamos que en la apuesta haya más de una persona
      users = db_query("SELECT distinct(user_id) as user_id from bets_tickets where bets_option_id IN (SELECT id from bets_options where bet_id = #{self.id})")
      if users.length == 0 then
        # do nothing
      elsif users.length == 1 then
        u = User.find(users[0]['user_id'].to_i)
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
    
    # Guardamos las stats de los users que han participado
    save_net_results
    self.save
  end
  
  def save_net_results
    # users = db_query("SELECT distinct(user_id) as user_id from bets_tickets where bets_option_id IN (SELECT id from bets_options where bet_id = #{self.id})")
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
  
  # TODO BIG MESS, refactor
  def self.open_bets(opts={})
    qcond = opts[:conditions] ?  " AND #{opts[:conditions]}" : ''
    #qcond = "code = #{opts[:code]} #{qcond}" if opts[:code]
    find(:published, 
         :conditions => "#{Bet::OPEN_BETS_SQL} #{qcond}", 
    :order => 'closes_on ASC, id ASC')
  end
  
  def self.awaiting_result(opts={})
    qcond = opts[:conditions] ?  " AND #{opts[:conditions]}" : ''
    self.find(:published, 
              :conditions => "#{Bet::AWAITING_RESULT_SQL} #{qcond}", 
    :order => 'closes_on DESC, id DESC')
  end
  
  def self.closed_bets(opts={})
    {:limit => :all}.merge(opts)
    qcond = opts[:conditions] ?  " AND #{opts[:conditions]}" : ''
    find(:published, 
         :conditions => "#{Bet::CLOSED_BETS_SQL} #{qcond}", 
    :order => 'closes_on DESC, id DESC', :limit => opts[:limit])
  end
  
  validates_uniqueness_of :title, :message => 'Nombre de la partida duplicado. Ejemplo de un nombre irrepetible: "Eurocup06 Quarters: oG vs P"'
end
