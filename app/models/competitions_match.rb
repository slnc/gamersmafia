class CompetitionsMatch < ActiveRecord::Base
  P1_WINS = 0
  TIE = 1
  P2_WINS = 2
  
  VALID_SCORING_SIMPLE_OPTIONS = [ :forfeit_participant1, 
                                   :forfeit_participant2,
                                   :participation, 
                                   :result
                                 ]
  
  belongs_to :competition
  belongs_to :event
  belongs_to :participant1, :class_name => 'CompetitionsParticipant', 
                            :foreign_key => 'participant1_id'
                            
  belongs_to :participant2, :class_name => 'CompetitionsParticipant', 
                            :foreign_key => 'participant2_id'
  
  has_many :competitions_matches_games_maps, :dependent => :destroy
  has_many :competitions_matches_uploads, :dependent => :destroy
  has_many :competitions_matches_reports, :dependent => :destroy
  
  before_create :check_play_on
  before_save :check_completed_on
  before_save :look_at_servers

  after_save :check_after_saves
  after_save :update_participants_indicators
  after_save :update_event

  after_destroy :destroy_my_event
  after_destroy :update_participants_indicators # necesario?

  observe_attr :result
  observe_attr :participant1_id
  observe_attr :participant2_id

  scope :accepted, :conditions => "accepted = 't'"
  scope :not_accepted, :conditions => "accepted = 'f'"
  #  after_save :reset_faith_indicators
  
  # TODO 
  #def reset_faith_indicators
  #  if self.completed?
  #    if self.competition.competitions_participants_type_id == 1 # user
  #      if self.participant1_id 
  #        rl = self.participant1.the_real_thing
  #        u
  #
  #    end
  #  end
  
  # Acepta un reto  
  
  # ahora busco todas las partidas de dichos competitions_participants que estén pendientes de aceptar resultado
  # arg1 puede ser array o int
  def self.find_pending_to_confirm_result(arg1, includes=[])
    participants_ids = arg1.is_a?(Array) ? arg1 : [arg1]
    self.find(:all, 
              :conditions => "(participant1_id IN (#{participants_ids.join(',')}) 
                               OR participant2_id IN (#{participants_ids.join(',')})) 
                          AND (accepted = 't' AND completed_on IS NULL) 
                          AND play_on < now()", :include => includes)
  end
  
  def equals_options(options)
    return unless self.play_on == options[:play_on] && self.servers == options[:servers] && self.ladder_rules == options[:ladder_rules]
    
    if maps > 0 # Comprobamos que la selección de mapas sea idéntica
      new_maps = options[:play_maps].collect {|k,map_id| map_id}
      old_maps = competitions_matches_games_map_ids
      new_maps.sort == old_maps.sort # atención, puede haber mapas elegidos más de una vez por eso hacemos esta comparación
    else
      true
    end
  end
  
  def rechallenge(options)
    # Cambiamos los participantes de lado
    tmp_p = participant1_id
    self.participant1_id = participant2_id
    self.participant2_id = tmp_p
    
    # Cambiamos las opciones
    self.play_on = options[:play_on]
    self.servers = options[:servers]
    self.ladder_rules = options[:ladder_rules]
    # Guardamos nuevos mapas
    if options[:play_maps] && competition.default_maps_per_match > 0
      competitions_matches_games_maps.clear
      options[:play_maps].each do |k,game_map_id|
        competitions_matches_games_maps.create({:games_map_id => game_map_id})
      end
    end
    self.save
    Notification.deliver_rechallenge(self.participant2.the_real_thing, 
                                     :participant => self.participant1)
  end
  
  
  def can_be_tied?
    c = self.competition
    
    has_participants = self.participant1_id && self.participant2_id
    no_tourney_round = !(c.kind_of?(Tournament) && 
                         c.competitions_types_options[:tourney_use_classifiers] == 'on' &&
                         self.stage >= c.tourney_rounds_starting_stage)
    
    has_participants && no_tourney_round
  end
  
  # Solo para ladders
  def accept_challenge
    self.update_attribute(:accepted, true)
    Notification.deliver_reto_aceptado(self.participant1.the_real_thing, 
                                       :participant => self.participant2)
  end
  
  # Solo para ladders
  def reject_challenge
    self.competition.log("#{self.participant2.name} rechaza el reto de #{self.participant1.name}")
    Notification.deliver_reto_rechazado(self.participant1.the_real_thing, 
                                        :participant => self.participant2)
    self.destroy
  end
  
  def update_participants_indicators
    self.participant1.update_indicator if self.participant1_id 
    self.participant2.update_indicator if self.participant2_id 
  end
  
  def destroy_my_event
    self.event.destroy if self.event
  end
  
  def to_s
    out = ''
    out << self.participant1.name if self.participant1_id
    out << " vs " << self.participant2.name if self.participant2_id
    out
  end
  
  def update_event
    # buscamos nuestro evento relacionado y si no lo tenemos creamos uno nuevo
    if self.event_id.nil? then
      # buscamos nuestro evento padre
      parent_event = self.competition.event
      raise 'no encuentro a mi padre!!' unless parent_event
      event_name = ''
      event_name << self.participant1.to_s if self.participant1_id 
      event_name << ' vs '
      event_name << self.participant2.to_s if self.participant2_id 
      mrman = User.find_by_login('mrman')
      raise ActiveRecord::RecordNotFound unless mrman
      my_event = Event.create({:title => event_name, 
        :parent_id => parent_event.id, 
        :starts_on => self.play_on ? self.play_on : self.created_on,
        :ends_on => self.play_on ? self.play_on : self.created_on,
        :website => "#{App.domain_arena}/competiciones/partida/#{self.id}",
        :user_id => mrman.id})
      
      self.competition.event.main_category.link(my_event.unique_content)
      Cms::publish_content(my_event, mrman)
      self.event_id = my_event.id
      self.save
    else # just update if we changed the participants
      
      if self.slnc_changed?(:participant1_id) || self.slnc_changed?(:participant2_id)
        event_name = ''
        event_name << self.participant1.to_s if self.participant1_id 
        event_name << ' vs '
        event_name << self.participant2.to_s if self.participant2_id
        e = self.event
        e.title = event_name
        e.save
      end
      
    end
  end
  
  def completed?
    # TODO añadir constraint dependiendo del tipo de confirmación de resultado
     ((participant1_confirmed_result && participant2_confirmed_result) || 
      admin_confirmed_result)
  end
  
  
  private
  # parsea los parámetros para confirmar el resultado de una partida simple
  def parse_scoring_simple(params)
    #params.assert_valid_keys(VALID_SCORING_SIMPLE_OPTIONS)
    if self.result != params[:result].to_i and self.forfeit_participant1 == params[:forfeit_participant1] and  self.forfeit_participant2 == params[:forfeit_participant2] then
      self.participant1_confirmed_result = false
      self.participant2_confirmed_result = false
    end
    
    self.result = params[:result].to_i
    self.forfeit_participant1 = params[:forfeit_participant1]
    self.forfeit_participant2 = params[:forfeit_participant2]
  end
  
  def parse_scoring_partial(params)
    everything_matches = self.forfeit_participant1 == params[:forfeit_participant1] and  self.forfeit_participant2 == params[:forfeit_participant2] and !@changed_completed_on_result
    
    self.forfeit_participant1 = params[:forfeit_participant1]
    self.forfeit_participant2 = params[:forfeit_participant2]
    
    sum_p1 = 0
    sum_p2 = 0
    self.maps.times do |time|
      cmgm = self.competitions_matches_games_maps.find(:all, :order => 'id ASC', :limit => 1, :offset => time)
      if cmgm.size > 0 then # si no había mapa es que ahora lo están eligiendo, lo guardamos
        cmgm = cmgm[0]
        # comprobamos si coinciden
        if everything_matches && \
         ((cmgm.partial_participant1_score != params[:partial_scores][cmgm.id.to_s][:participant1].to_i) || \
         (cmgm.partial_participant2_score != params[:partial_scores][cmgm.id.to_s][:participant2].to_i))
          everything_matches = false
        end
        
        # guardamos independientemente
        cmgm.partial_participant1_score = params[:partial_scores][cmgm.id.to_s][:participant1].to_i
        cmgm.partial_participant2_score = params[:partial_scores][cmgm.id.to_s][:participant2].to_i
      else # estamos creando asociación entre competitions_matches y games_maps
        everything_matches = false
        map = self.competition.games_maps.find(params[:played_maps][time.to_s])
        cmgm = self.competitions_matches_games_maps.create(:games_map_id => map.id)
        cmgm.partial_participant1_score = params[:partial_scores_new_maps][time.to_s][:participant1].to_i
        cmgm.partial_participant2_score = params[:partial_scores_new_maps][time.to_s][:participant2].to_i
      end
      
      sum_p1 += cmgm.partial_participant1_score
      sum_p2 += cmgm.partial_participant2_score
      if not everything_matches then # si todo matchea no tenemos q guardar aquí nada
        cmgm.save
      end
    end
    
    self.score_participant1 = sum_p1
    self.score_participant2 = sum_p2
    
    if sum_p1 > sum_p2 then
      self.result = 0
    elsif sum_p1 == sum_p2 then
      self.result = 1
    else
      self.result = 2
    end
    
    if not everything_matches then
      self.participant1_confirmed_result = false
      self.participant2_confirmed_result = false
    end
  end
  
  def parse_scoring_simple_per_map(params)
    if self.forfeit_participant1 != params[:forfeit_participant1] || self.forfeit_participant2 != params[:forfeit_participant2] ||
      self.score_participant1 != params[:score_participant1].to_i ||
      self.score_participant2 != params[:score_participant2].to_i then
      
      self.forfeit_participant1 = params[:forfeit_participant1]
      self.forfeit_participant2 = params[:forfeit_participant2]
      
      self.participant1_confirmed_result = false
      self.participant2_confirmed_result = false
    end
    
    # TODO sanity check
    self.score_participant1 = params[:score_participant1].to_i
    self.score_participant2 = params[:score_participant2].to_i
    self.score_participant1 = 10 if params[:score_participant1].to_i > 10
    self.score_participant2 = 10 if params[:score_participant2].to_i > 10
    
    # TODO trata esto de otra forma
    if self.score_participant1 + self.score_participant2 > 10 then
      self.score_participant1 = 0
      self.score_participant2 = 0
    end
    
    if self.score_participant1 > self.score_participant2 then
      self.result = 0
    elsif self.score_participant1 == self.score_participant2 then
      self.result = 1
    else
      self.result = 2
    end
    
    # nota: hacemos esto por si se juega un torneo en el que tiene que
    # haber diferencia de 2 mapas y se van de lo calculado por ej
    self.maps = self.score_participant1 + self.score_participant2
  end
  
  
  public
  # Pueden modificar el resultado o bien un participante del reto una vez esté pendiente de confirmarse el resultado o bien si es una ladder y se es admin de la ladder y no ha pasado más de 1 mes
  def can_set_result(user)
    c = self.competition
    basic = (c.state == Competition::STARTED && self.accepted?)
    completed_admin_on_ladder = (c.kind_of?(Ladder) && c.state == Competition::STARTED && (c.user_is_admin(user.id) || c.user_is_supervisor(user.id)) && completed_on && completed_on > 1.month.ago)
    participants = (!self.completed? && !awaiting_participant? && (c.user_is_admin(user.id) || c.user_is_supervisor(user.id) || c.user_is_participant_of_match(user.id, self)))
    #puts "(#{!self.completed?} && #{!awaiting_participant?} && (#{c.user_is_admin(user.id)} || #{c.user_is_supervisor(user.id)} || #{c.user_is_participant_of_match(user.id, self)}))"
    #puts "#{basic} && (#{participants} || #{completed_admin_on_ladder} || (#{user.login.downcase} == 'mrman'))"
    if basic && (participants || completed_admin_on_ladder || (user.login.downcase == 'mrman'))
      true
    else
      false
    end
  end
  alias :can_set_result? :can_set_result 
  
  # Completa la partida
  def complete_match(user, params, defaulting=false)
    raise AccessDenied unless can_set_result(user)
    
    if !defaulting then
      # si hay un resultado ya puesto y no es igual al enviado quitamos las
      # confirmaciones que haya
      params[:forfeit_participant1] = %w(both p1).include?(params[:participation]) ? false : true
      params[:forfeit_participant2] = %w(both p2).include?(params[:participation]) ? false : true
      
      case self.competition.scoring_mode
        when Competition::SCORING_SIMPLE:
        parse_scoring_simple(params)
        when Competition::SCORING_PARTIAL:
        parse_scoring_partial(params)
        when Competition::SCORING_SIMPLE_PER_MAP:
        parse_scoring_simple_per_map(params)
      else
        raise 'unimplemented'
      end
    else # we are defaulting this match by forfeiting
      params[:forfeit_participant1] = true
      params[:forfeit_participant2] = true
      case self.competition.scoring_mode
        when Competition::SCORING_SIMPLE:
        parse_scoring_simple(params.merge({:result => TIE}))
        when Competition::SCORING_PARTIAL:
        self.maps = 0
        parse_scoring_partial(params)
        when Competition::SCORING_SIMPLE_PER_MAP:
        parse_scoring_simple_per_map(params.merge({:score_participant1 => 0, :score_participant2 => 0}))
      else
        raise 'unimplemented'
      end
    end
    
    # dependiendo del tipo de usuario que es ponemos el flag de que lo ha confirmado
    if (self.competition.user_is_admin(user.id) || self.competition.user_is_supervisor(user.id) || user.login.downcase == 'mrman') or
     (self.competition.kind_of?(Tournament) and (self.participant2_id.nil? and not self.awaiting_participant?)) then
      self.admin_confirmed_result = true
    else
      if self.competition.user_is_participant1_of_match(user.id, self)
        self.participant1_confirmed_result = true
      else
        self.participant2_confirmed_result = true
      end
    end
    
    if not self.completed? then
      self.competition.log("Resultado de partido <a href=\"/competiciones/partida/#{self.id}\">#{self}</a> confirmado")
      #        TODO: del controller flash[:notice] = 'Resultado enviado correctamente. El otro participante debe confirmar el resultado.'
    else
      #        flash[:notice] = 'Resultado confirmado correctamente. La partida ya está completa.'
      # aumentamos stats de winners y losers
      case self.result
        # TODO código duplicado
        when 0
        p1 = self.participant1
        p1.wins += 1 if p1
        p2 = self.participant2
        p2.losses += 1 if p2
        
        when 1
        if forfeit_participant1 && forfeit_participant2 then # double forfeit  
          p1 = self.participant1
          p1.losses += 1 if p1
          p2 = self.participant2
          p2.losses += 1 if p2
        else
          p1 = self.participant1
          p1.ties += 1 if p1
          p2 = self.participant2
          p2.ties += 1 if p2
        end
        
        when 2
        p1 = self.participant1
        p1.losses += 1 if p1
        p2 = self.participant2
        p2.wins += 1 if p2
      end
      p1.save if p1
      p2.save if p2
    end
    
    self.save
  end
  
  def reset_confirmed_result
    raise "impossible" unless self.completed?
    self.participant1_confirmed_result = false
    self.participant2_confirmed_result = false
    self.admin_confirmed_result = false
    self.result = nil
    self.score_participant1 = nil
    self.score_participant2 = nil
    self.completed_on = nil
    self.save
  end
  
  def awaiting_participant?
    # buscamos partidas que no sean del primer round y que falte algún
    # participante y que en la ronda anterior falte algún partido por confirmar
    self.stage > 0 && \
     (participant1_id.nil? or participant2_id.nil?) && \
     (self.competition.competitions_matches.count(:conditions => "stage = #{self.stage - 1} 
                                              AND NOT ((participant1_confirmed_result = 't' AND participant2_confirmed_result = 't') 
                                               OR admin_confirmed_result = 't')") > 0)
  end
  
  def winner
    case result
      when P1_WINS:
      self.participant1
      when TIE:
      'Empate'
      when P2_WINS:
      self.participant2
    else
      raise 'ERROR: match unconfirmed'
    end
  end
  
  # Se usa para permisos de reports y archivos
  def user_can_upload_attachment(user)
    if self.completed_on.nil? or self.completed_on > Time.now.ago(86400 * 30) then
      return true if competition.user_is_admin(user) || competition.user_is_supervisor(user)
      case self.competition.competitions_participants_type_id
        when Competition::USERS:
        activep = self.competition.get_active_participant_for_user(user)
        competition.user_is_participant(user.id) && (self.participant1_id == activep.id || self.participant2_id == activep.id)
        when Competition::CLANS:
        # miramos a ver si es miembro de alguno de los dos clanes
        if self.participant1_id
          allowed_players = self.participant1.the_real_thing.members_of_game(competition.game)
          allowed_players ||= []
          allowed_players += self.participant1.the_real_thing.admins
          allowed_players_ids = []
          allowed_players.each { |player| allowed_players_ids<< player.id }
          allowed_players_ids.include?(user.id)
        elsif self.participant2_id # buscamos en el otro participante
          allowed_players = self.participant2.the_real_thing.members_of_game(competition.game)
          allowed_players ||= []
          allowed_players += self.participant2.the_real_thing.admins
          allowed_players_ids = []
          allowed_players.each { |player| allowed_players_ids<< player.id }
          allowed_players_ids.include?(user.id)
        else
          false
        end
      end
    else
      false
    end
  end
  
  
  # private
  def check_completed_on
    return false if self.participant1_id != nil && self.participant1_id == self.participant2_id
    @changed_completed_on_result = (self.slnc_changed?(:result) && self.completed_on)
    
    if self.completed? && self.completed_on.nil? then # lo estamos completando
      self.completed_on = Time.now
      case self.competition.class.name
        when 'Ladder': update_ladder_points
        when 'League': update_league_points
      end
      
      # Damos puntos de fe
      self.participant1.users.each { |u| Faith.give(u, Faith::FPS_ACTIONS['competitions_match']) } if self.participant1_id and not self.forfeit_participant1
      self.participant2.users.each { |u| Faith.give(u, Faith::FPS_ACTIONS['competitions_match']) } if self.participant2_id and not self.forfeit_participant2
    end
  end
  
  def update_league_points
    p1 = self.participant1
    p2 = self.participant2
    # puts "#{p1} vs #{p2}"
    p1.points = p1.wins * 3 + p1.ties * 1;
    p2.points = p2.wins * 3 + p2.ties * 1;
    p1.save
    p2.save
  end
  
  # TODO ladder specific
  def update_ladder_points
    p1 = self.participant1
    p2 = self.participant2
    # puts "#{p1} vs #{p2}"
    p1.points = 1000 if p1.points.nil?
    p2.points = 1000 if p2.points.nil?
    
    expected_p1 = 1 / (1 + 10 **((p2.points - p1.points) / 400.0))
    expected_p2 = 1 / (1 + 10 **((p1.points - p2.points) / 400.0))
    
    case self.result
      when P1_WINS:
      p1_score = 1
      p2_score = 0
      when TIE:
      if forfeit_participant1 && forfeit_participant2 # double forfeit: points for no one
        p1_score = 0
        p2_score = 0
      else
        p1_score = 0.5
        p2_score = 0.5
      end
      when P2_WINS:
      p1_score = 0
      p2_score = 1
    end
    
    # puts "exp1: #{expected_p1} exp2: #{expected_p2} p1_score: #{p1_score} p2_score: #{p2_score} p1_points: #{p1.points} p2_points: #{p2.points}"
    p1.points += Competitions.k_factor(p1)*(p1_score - expected_p1)
    p2.points += Competitions.k_factor(p2)*(p2_score - expected_p2)
    # puts "p1_new_points: #{p1.points} p2_new_points: #{p2.points}"
    p1.save
    p2.save
  end
  
  def check_after_saves
    case self.competition.class.name
      when 'Tournament':
      after_save_tourney
      
      when 'Ladder':
      if @changed_completed_on_result
        Competitions.recalculate_points(self.competition)
      end
    end
  end
  
  # TODO not clean
  #
  def after_save_tourney
    # si no estamos en la fase final buscamos la partida a la que le damos el
    # winner y chequeamos que tiene el participant correspondiente puesto
    # Nota: ya tenemos en cuenta que se edite después de haber sido completada
    # por primera vez
    self.competition.match_completed(self) if self.completed?
  end
  
  def look_at_servers
    return true if servers.nil? || servers.strip == ''
    # sanitizing string
    self.servers = servers.strip.gsub(' ', ',').gsub(',,',',')
    seen_servers = []
    all_valid = true
    new_servers_string = ''
    self.servers.split(',').each do |server|
      next unless all_valid
      next if seen_servers.include?(server) # no añadimos repetidos
      all_valid = (Cms::IP_REGEXP.match(server)) || (Cms::DNS_REGEXP.match(server)) || false
      if all_valid 
        seen_servers<< server
        new_servers_string<< server<<','
      end
    end
    new_servers_string.gsub!(/(,)$/, '')
    self.servers =new_servers_string
    all_valid
  end
  
  def check_play_on
    if new_record? && play_on && play_on < Time.now
      self.errors.add('play_on', 'La fecha de comienzo de la partida no puede estar en el pasado')
      false
    else
      true
    end
  end
  # TODO Validar que participant1_id != participant2_id
end
