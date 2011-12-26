# [states] 0=previo a inscripciones, 1=inscripciones abiertas, 2=inscripciones cerradas, 3=desarrollo torneo, 4=torneo cerrado 
# [competitions_participants_type_id] 1=user, 2=clan
# [random_map_selection_mode] 0=completamente random, 1=el mismo para todas las partidas de una misma stage
# [scoring_mode] 0=simple, 1=partial_scoring, una puntuación por mapa y participante. gana el que más sume, 2=un punto por mapa ganado, gana el que más sume
# [timetable_for_matches]
# - <tt>0</tt> - No se pone fecha ni hora a las partidas
# - <tt>1</tt> - Distribuir uniformemente a lo largo de x semanas con y días de
# la semana válidos y z horas para cada día.
#
class Competition < ActiveRecord::Base
  COMPLETED_ON_SQL = 'completed_on is not null'
  CREATED = 0
  INSCRIPTIONS_OPEN = 1
  INSCRIPTIONS_CLOSED = 2
  STARTED = 3
  CLOSED = 4
  
  SCORING_SIMPLE = 0  # fulanito gana o empate
  SCORING_PARTIAL = 1 # especificar puntos por cada mapa jugado. Gana el que más puntos sume
  SCORING_SIMPLE_PER_MAP = 2 # 1 punto por mapa ganado. Gana el que más mapas haya ganado.
  
  STATES = { 0 => 'created',
    1 => 'inscriptions_open',
    2 => 'inscriptions_closed',
    3 => 'started',
    4 => 'closed'
  }
  
  STATES_ES= { 0 => 'En preparación',
    1 => 'Inscripciones abiertas',
    2 => 'Inscripciones cerradas',
    3 => 'Iniciada',
    4 => 'Cerrado'
  }
  
  USERS = 1
  CLANS = 2
  COMPETITIONS_PARTICIPANTS_TYPES_ES = { 1 => 'Usuarios',
    2 => 'Clanes' }
  
  has_many :competitions_logs_entries
  has_many :competitions_participants, :dependent => :destroy
  has_many :allowed_competitions_participants, :dependent => :destroy
  has_many :competitions_matches, :dependent => :destroy
  has_many :competitions_sponsors, :dependent => :destroy
  has_and_belongs_to_many :games_maps
  serialize :timetable_options, HashWithIndifferentAccess
  serialize :competitions_types_options, HashWithIndifferentAccess
  after_create :create_contents_categories
  
  belongs_to :game
  belongs_to :competitions_participants_type
  belongs_to :event
  
  validates_uniqueness_of :name
  plain_text :name
  
  before_destroy :return_fee
  
  file_column :header_image
  
  has_users_role 'CompetitionAdmin'
  has_users_role 'CompetitionSupervisor'
  
  has_bank_account
  
  def get_related_portals
    self.game.portals
  end
  
  observe_attr :state
  
  
  def can_recreate_matches?
   (self.kind_of?(League) || self.kind_of?(Tournament)) && self.competitions_matches.count(:conditions => 'completed_on is NOT NULL') == 0
  end
  
  def can_delete_participants?
    self.state < 3 || self.competitions_matches.count(:conditions => 'completed_on is NOT NULL') == 0
  end
  
  # Busca competiciones relacionadas con el usuario, ya sean competiciones de
  # usuarios o de clanes. Si el usuario es admin también devolverá la competición
  # aunque no sea participante
  scope :related_with_user, lambda { |user| 
    ids = [0]
    Clan.related_with_user(user.id).compact.each { |c| ids<< c.id }
    
    { :conditions => "id IN (SELECT role_data::int4 FROM users_roles WHERE user_id = #{user.id} AND role IN ('CompetitionAdmin', 'CompetitionSupervisor'))
                                           or id IN (SELECT a.id 
                                                       FROM competitions a 
                                                       JOIN competitions_participants b on a.id = b.competition_id 
                                                      WHERE a.competitions_participants_type_id = 1 
                                                        AND b.participant_id = #{user.id})
                                           or id IN (SELECT a.id 
                                                       FROM competitions a 
                                                       JOIN competitions_participants b on a.id = b.competition_id 
                                                      WHERE a.competitions_participants_type_id = 2 
                                                        AND b.participant_id IN (#{ids.join(',')}))"}
  }
  
  
  scope :related_with_clan, lambda { |clan| { :conditions => "id IN (SELECT competition_id 
                                                                             FROM competitions_participants 
                                                                            WHERE participant_id = #{clan.id} 
                                                                              AND competition_id IN (SELECT id 
                                                                                                       FROM competitions 
                                                                                                      WHERE competitions_participants_type_id = #{Competition::CLANS}))"}}
  scope :active, :conditions => "state < #{CLOSED}"
  scope :started, :conditions => "state = #{Competition::STARTED}"
  
  def self.update_user_indicator(user)
    # TODO copypasted de warning_list.rhtml
    clans = Clan.leaded_by(user.id)
    clans_ids = [0]
    clans.each { |clan| clans_ids<< clan.id }
    participants = CompetitionsParticipant.find(:all, :conditions => "competition_id IN (SELECT id FROM competitions WHERE state = 3) 
  AND ((participant_id = #{user.id} AND competitions_participants_type_id = 1) OR (participant_id IN (#{clans_ids.join(',')}) AND competitions_participants_type_id = 2))")
    
    participants_ids = [0]
    participants.each { |participant| participants_ids<< participant.id }
    # La siguiente query es una combinación de la query para partidas pendientes de confirmar resultado y la query para ver resultados pendientes de responder
    # buscamos partidas pendientes de aceptar por el user
    update_indicator = CompetitionsMatch.not_accepted.count(:conditions => "participant2_id IN (#{participants_ids.join(',')})") > 0
    if !update_indicator
      # Buscamos partidas pendientes de confirmar resultado por este lado
      update_indicator = CompetitionsMatch.accepted.count(:conditions => "(((participant1_id IN (#{participants_ids.join(',')}) AND participant1_confirmed_result = 'f') OR 
                                                                                           (participant2_id IN (#{participants_ids.join(',')}) AND participant2_confirmed_result = 'f')) AND play_on < now() AND admin_confirmed_result = 'f')") > 0
    end
    
    user.enable_competition_indicator = update_indicator
    user.save
  end
  
  # esta competición tiene opciones específicas del tipo que sea? opciones de ladder, torneo o liga?
  def has_options?
    false
  end
  
  def admins
    UsersRole.find(:all, :conditions => ["role = 'CompetitionAdmin' AND role_data = ?", self.id.to_s], :include => :user, :order => 'lower(users.login)').collect { |ur| ur.user }
  end
  
  def supervisors
    UsersRole.find(:all, :conditions => ["role = 'CompetitionSupervisor' AND role_data = ?", self.id.to_s], :include => :user, :order => 'lower(users.login)').collect { |ur| ur.user }
  end
  
  def add_supervisor(user)
    if UsersRole.count(:conditions => ["role = 'CompetitionSupervisor' AND user_id = ? AND role_data = ?", user.id, self.id.to_s]) == 0
      ur = UsersRole.new(:role => 'CompetitionSupervisor', :user_id => user.id, :role_data => self.id.to_s)
      ur.save
    end
    Cache::Competition.expire_competitions_lists(user)
  end
  
  def add_admin(user)
    if UsersRole.count(:conditions => ["role = 'CompetitionAdmin' AND user_id = ? AND role_data = ?", user.id, self.id.to_s]) == 0
      ur = UsersRole.new(:role => 'CompetitionAdmin', :user_id => user.id, :role_data => self.id.to_s)
      ur.save
    end
    Cache::Competition.expire_competitions_lists(user)
  end
  
  def del_admin(u)
    ur = UsersRole.find(:first, :conditions => ["role = 'CompetitionAdmin' AND user_id = ? AND role_data = ?", u.id, self.id.to_s])
    ur.destroy if ur
    Cache::Competition.expire_competitions_lists(u)
  end
  
  def del_supervisor(u)
    ur = UsersRole.find(:first, :conditions => ["role = 'CompetitionSupervisor' AND user_id = ? AND role_data = ?", u.id, self.id.to_s])
    ur.destroy if ur
    Cache::Competition.expire_competitions_lists(u)
  end
  
  def user_is_admin(user_id)
    UsersRole.count(:conditions => ["role = 'CompetitionAdmin' AND role_data = ? AND user_id = ?", self.id.to_s, user_id]) > 0
  end
  
  def user_is_supervisor(user_id)
    UsersRole.count(:conditions => ["role = 'CompetitionSupervisor' AND role_data = ? AND user_id = ?", self.id.to_s, user_id]) > 0
  end
  
  
  def add_participant(entity)
    raise 'Imposible' unless self.can_add_participants?
    if self.competitions_participants_type_id == USERS then
      raise 'Type Error' unless entity.class.name == 'User'
      name = entity.login
      roster = entity.competition_roster ? entity.competition_roster : 'images/default_avatar.jpg'
      participant_cls = 'user'
      participant = entity
    elsif self.competitions_participants_type_id == Competition::CLANS then
      participant_cls = 'clan'
      raise 'Type Error' unless entity.class.name == 'Clan'
      participant = entity
      name = entity.tag
      roster = entity.competition_roster ? entity.competition_roster : 'images/default_avatar.jpg'
    else
      raise 'invalid competitions_participants_type_id'
    end
    
    self.competitions_participants.create({:participant_id => participant.id, 
      :name => name, 
      :competitions_participants_type_id => self.competitions_participants_type_id, 
      :roster => roster})
    self.log("Añadido manualmente participante <strong>#{name}</strong>")
    self.recreate_matches if self.state == 2 && %w(Tourney League).include?(self.class.name)
  end
  
  # join the competition if possible. Returns the CompetitionsParticipant entity if everything ok or raises an exception if can't be added
  # TODO: check state!!!
  # TODO refactor, more explicit, messy
  # TODO algo duplicado de función anterior
  def join(user)
    if self.competitions_participants_type_id == USERS then
      name = user.login
      roster = user.competition_roster ? user.competition_roster : 'images/default_avatar.jpg'
      participant_cls = 'user'
      participant = user
    elsif self.competitions_participants_type_id == Competition::CLANS then
      participant_cls = 'clan'
      clan = Clan.find(user.last_clan_id)
      raise AccessDenied unless clan.user_is_clanleader(user.id)
      participant = clan
      name = clan.tag
      roster = clan.competition_roster ? clan.competition_roster : 'images/default_avatar.jpg'
    else
      raise 'invalid competitions_participants_type_id'
    end
    
    # TODO chequear que no esté ya añadido
    # TODO no limpio
    # denegar si no tiene dinero
    if self.invitational && self.allowed_competitions_participants.find_by_participant_id(participant.id).nil?
      raise 'No puedes inscribirte porque no has sido invitado a esta competición.'
    else
      if self.fee and participant.cash < self.fee then
        raise 'No tienes suficiente dinero para inscribirte'
      else
        new_participant = self.competitions_participants.create({:participant_id => participant.id, :name => name, :competitions_participants_type_id => self.competitions_participants_type_id, :roster => roster})
        if new_participant
          new_participant.users.each do |u|
            u.last_competition_id = self.id
            u.save
          end
          
          self.log("#{name} se inscribe en la competición")
          # TODO refactor goddamit
          Bank.transfer(participant, self, self.fee, "Pago inscripción en \"#{self.name}\"") if self.fee
          new_participant # only valid exit point
        else
          case self.competitions_participants_type_id
            when 1:
            if self.user_is_participant(user.id)
              raise 'Ya estás inscrito en esta competición.'
            else
              raise 'Error desconocido al intentar inscribirte.'
            end
            when 2:
            raise 'Error desconocido al intentar inscribir a tu clan.'
          else
            raise 'unimplemented'
          end
        end # check participants_type_id
      end # check fee
    end # check invitational
  end
  
  def return_fee
    if self.fee? then
      self.competitions_participants.each { |p| Bank.transfer(self, p.the_real_thing, self.fee, "Devolución de inscripción en #{self.name}") }
    end
  end
  
  def ends_on
    self.closed_on or self.estimated_end_on or Time.local(Time.now.year + 1)
  end
  
  def create_contents_categories
    mrman = User.find_by_login('mrman')
    raise ActiveRecord::RecordNotFound unless mrman
    
    
    e = Event.create({:title => self.name, 
      :description => self.description, 
      :starts_on => self.created_on, 
      :ends_on => self.ends_on, 
      :user_id => mrman.id, 
      :website => "http://#{App.domain_arena}/competiciones/show/#{self.id}"})
    e.change_state(Cms::PUBLISHED, mrman)
    Term.single_toplevel(:game_id => self.game_id).link(e.unique_content)
    self.event_id = e.id
    
    arena_tld = Term.single_toplevel(:slug => 'arena')
    # TODO reordenar esto
    game_term = arena_tld.children.find(:first, :conditions => ['name = ? AND taxonomy = \'TopicsCategory\'', self.game.name])     
    game_term = arena_tld.children.create(:name => self.game.name, :taxonomy => 'TopicsCategory') if game_term.nil?
    newforum = game_term.children.create(:name => self.name, :taxonomy => 'TopicsCategory')
    #self.terms= game_term.id # TODO bug
    self.save
  end
  
  def myforum
    arena_tld = Term.single_toplevel(:slug => 'arena')
    game_term = arena_tld.children.find(:first, :conditions => ['name = ? AND taxonomy = \'TopicsCategory\'', self.game.name])
    return nil unless game_term
    game_term.children.find(:first, :conditions => ["name = ? AND taxonomy = 'TopicsCategory'", self.name])
  end
  
  
  public
  def can_add_participants?
    state < 3
  end
  
  def can_modify_allowed_participants?
    invitational? && (state < 3 || self.kind_of?(Ladder))
  end
  
  def log(msg)
    self.competitions_logs_entries.create({:message => msg})
  end
  
  def can_be_closed?
    if state != 3 then
      false
    elsif self.kind_of?(Ladder) # las ladders siempre se pueden cerrar, no? TODO mejor bloquearla de alguna forma?
      true
    else
      if self.matches(:result_pending).size == 0 && \
        self.matches(:completed, :conditions => 'completed_on > now() - \'7 days\'::interval', :limit => 1).size == 0 then
        true
      else
        false
      end
    end
  end
  
  def to_s
    self.name
  end
  
  def current_state
    STATES[self.state]
  end
  
  VALID_MATCHES_OPTIONS = [:participants, :participant, :participant1, :participant2, :stage, :limit, :conditions, :order, :count, :forfeit]
  
  # Devuelve todas las partidas del participante elegido.
  # La primera opción puede ser:
  # - <tt>:completed</tt> - devuelve las partidas completadas
  # - <tt>:result_pending</tt> - partidas con resultado pendiente de confirmar
  # - <tt>:unapproved_by_self</tt> - en ladders, devuelve los retos que todavía no ha aceptado el participante
  # - <tt>:unapproved_by_others</tt> - en ladders, devuelve los retos del participante que todavía no han sido aceptados
  #
  # Y el resto de opciones pueden ser:
  # - <tt>:limit</tt> - limita el total de partidas devueltas
  # - <tt>:order</tt> - limita el total de partidas devueltas
  # 
  # Ejemplos:
  # - c.matches(:completed)
  # - c.matches(:completed, :participant => someparticipant)
  # - c.matches(:completed, :participant => someparticipant, :count => true)
  # - c.matches(:all, :participant1 => someparticipant)
  # - c.matches(:result_pending, :participant => someparticipant)
  # - c.matches(:result_pending, :participants => [someparticipant_a, someparticipant_b])
  def matches(mode, *args)
    def_options = {:conditions => nil, :limit => nil, :order => nil, :count => false}
    options = args.last.is_a?(Hash) ? def_options.merge(args.pop) : def_options
    options.assert_valid_keys(VALID_MATCHES_OPTIONS)
    sql_cond = ''
    
    case mode
      when :all
      if options.has_key?(:participant)
        sql_cond << "(participant1_id = #{options[:participant].id} OR participant2_id = #{options[:participant].id})"
      end
      when :approved
      sql_cond << 'accepted = \'t\''
      if options.has_key?(:participant)
        sql_cond << " AND (participant1_id = #{options[:participant].id} OR participant2_id = #{options[:participant].id})"
      end
      when :completed
      sql_cond << COMPLETED_ON_SQL
      
      if options.has_key?(:participant)
        if options.has_key?(:forfeit) and options[:forfeit] == false # TODO solo soportamos :forfeit => false
          sql_cond << " and ((participant1_id = #{options[:participant].id} and forfeit_participant1 is false) or (participant2_id = #{options[:participant].id} and forfeit_participant2 is false))"
        else
          sql_cond << " and (participant1_id = #{options[:participant].id} or participant2_id = #{options[:participant].id})"
        end
      end
      
      when :result_pending
      sql_cond << 'accepted = \'t\' and not ((participant1_confirmed_result = \'t\' and participant2_confirmed_result = \'t\') or admin_confirmed_result = \'t\')'
      if options.has_key?(:participant)
        sql_cond << ' AND (participant1_id = ' << options[:participant].id.to_s << ' OR participant2_id = ' << options[:participant].id.to_s << ')'
      elsif options.has_key?(:participants)
        pa = options[:participants][0].id
        pb = options[:participants][1].id
        sql_cond << " AND ((participant1_id = #{pa} and participant2_id = #{pb}) OR (participant1_id = #{pb} and participant2_id = #{pa}))"
      end
      
      when :octavos
        sql_cond << "stage = (select max(stage) from competitions_matches where competition_id = #{self.id}) - 3"
      when :cuartos
      sql_cond << "stage = (select max(stage) from competitions_matches where competition_id = #{self.id}) - 2"
      
      when :semifinales
      sql_cond << "stage = (select max(stage) from competitions_matches where competition_id = #{self.id}) - 1"
      
      when :final
      sql_cond << "stage = (select max(stage) from competitions_matches where competition_id = #{self.id})"
      
      when :unapproved
      sql_cond << 'accepted = \'f\''
      if options.has_key?(:participant)
        sql_cond << ' AND (participant1_id = ' << options[:participant].id.to_s << ' OR participant2_id = ' << options[:participant].id.to_s << ')'
      elsif options.has_key?(:participants)
        pa = options[:participants][0].id
        pb = options[:participants][1].id
        sql_cond << " AND ((participant1_id = #{pa} and participant2_id = #{pb}) OR (participant1_id = #{pb} and participant2_id = #{pa}))"
      end
      
      when :unapproved_by_participant
      raise ':participant not found in options' unless options.has_key?(:participant)
      sql_cond << "accepted = 'f' and participant2_id = #{options[:participant].id}"
      
      when :unapproved_by_adversaries
      raise ':participant not found in options' unless options.has_key?(:participant)
      sql_cond << "accepted = 'f' and participant1_id = #{options[:participant].id}"
    else raise 'unimplemented'
    end
    
     (sql_cond << ' AND ' << options[:conditions]) unless options[:conditions].nil?
    
    if options[:count]
      self.competitions_matches.count(:conditions => sql_cond)
    else
      self.competitions_matches.find(:all, :conditions => sql_cond, :limit => options[:limit], :order => options[:order])
    end
  end
  
  
  def user_can_challenge(user)
    return false unless self.kind_of?(Ladder) && self.state == 3
    participant = self.get_active_participant_for_user(user)
    return false if participant.nil?
    return false if self.competitions_participants_type_id == 2 and not participant.the_real_thing.user_is_clanleader(user.id)
    true
  end
  
  def get_active_participant_for_user(user)
    case competitions_participants_type_id
      when USERS:
      p = competitions_participants.find(:first, :conditions => ['participant_id = ?', user.id])
      when CLANS:
      participants = competitions_participants.find(:all, :conditions => "participant_id IN (#{(user.clans_ids + [0]).join(',')})")
      # si participants > 0 el usuario es admin de más de un clan que están registrados como participants en esta competi
      # Devolvemos un clan aleatorio, habría que avisarle de alguna forma, no?
      if participants.size > 0 then 
        participants.each do |p|
          p = nil unless p.the_real_thing.user_is_clanleader(user.id)
          break if p
        end
      end
    else
      raise 'unimplemented'
    end
    p
  end
  
  def get_active_participant_for_clan(clan)
    raise "Impossible, competition is for users" if self.competitions_participants_type_id == USERS
    self.competitions_participants.find_by_participant_id(clan.id)
  end
  
  def winners(limit=:all)
    self.competitions_participants.find(:all, :conditions => 'wins > 0 or losses > 0 or ties > 0', :order => 'points DESC, lower(name) ASC', :limit => limit)
  end
  
  def has_advanced?
    self.state == 2 && self.class.name == 'Tournament' && self.competitions_types_options[:tourney_use_classifiers]
  end
  
  #
  # Devuelve true si se puede cambiar al estado dado y false en caso contrario
  #
  def switch_to_state(new_state_id)
    if (not self.kind_of?(Ladder)) && state + 1 != new_state_id then
      false
    else
      # TODO hacer comprobaciones necesarias según la etapa actual de la
      # competición
      case new_state_id
        when 1:
        raise 'impossible' unless self.configured?
        # Mandamos invitación a usuarios invitados
        if invitational?
          self.allowed_competitions_participants.each do |participant|
            # No usamos la de competicion pq así nos ahorramos la query a competition de allowed_participant.real_thing
            if self.competitions_participants_type_id == USERS
              recipients = [User.find(participant.participant_id)]
            else
              recipients = Clan.find(participant.participant_id).admins
            end
            if self.send_notifications?
              recipients.each { |rcpt| Notification.deliver_invited_participant(rcpt, { :competition => self }) }
            end
          end
        end
        when 2:
        case self.class.name
          when 'League':
          setup_matches_league
          when 'Tournament':
          if self.competitions_types_options[:tourney_use_classifiers] then
            setup_matches_tourney_classifiers
          else
            setup_matches_tourney
          end
          when 'Ladder':
          # do nothing here
        else
          raise 'unimplemented'
        end
        
        setup_times_for_matches if self.timetable_for_matches
        setup_maps_for_matches if self.random_map_selection_mode
        
        when 3:
        raise Exception unless self.class.name == 'Ladder' || self.competitions_participants.count > 1
        if self.send_notifications?
          self.competitions_participants.each do |participant| 
            Notification.deliver_competition_started(participant.the_real_thing, { :competition => self })
          end
        end
        when 4:
        raise 'impossible' unless self.can_be_closed?
        if self.fee? then # repartimos el dinero entre los ganadores
          # Siempre va a haber 3 ganadores porque es el mínimo para crear una competición
          third_place = self.cash * 0.16
          second_place = self.cash * 0.32 
          first_place = self.cash - second_place - third_place
          w = self.winners(3)
          Bank.transfer(self, w[2].the_real_thing, third_place, "Premio por el 3er puesto en \"#{self.name}\"") if w[2] && third_place > 0
          Bank.transfer(self, w[1].the_real_thing, second_place, "Premio por el 2º puesto en \"#{self.name}\"") if w[1] && second_place > 0
          Bank.transfer(self, w[0].the_real_thing, first_place, "Premio por el 1er puesto en \"#{self.name}\"") if w[0] && first_place > 0
        end
        self.closed_on = Time.now
      end
      
      self.state = new_state_id
      self.log("Competición avanzada a #{STATES_ES[self.state]}")
      self.save # esta función debe devolver true/false
    end
  end
  
  def recreate_matches
    self.log("Partidas recreadas")
    self.competitions_matches.clear
    self.state = 1
    return unless self.switch_to_state(2)
    self.competitions_participants.each do |cp|
      cp.update_attributes(:wins => 0, :losses => 0, :ties => 0)
    end
    true
  end
  
  def setup_matches_play_times
    return unless self.timetable_for_matches == 1
    # TODO unimplemented
  end
  
  def configured?
    self.description.to_s == '' ? false : true
  end
  
  def current_match_stage
    # buscamos la partida de una stage más baja que no haya sido confirmada
    # TODO cuando pongamos si los admins deben confirmar o no resultado habrá
    # que cambiar esta consulta
    f = self.competitions_matches.find(:first, :conditions => 'NOT ((participant1_confirmed_result = \'t\' and participant2_confirmed_result = \'t\') or admin_confirmed_result = \'t\')', :order => 'stage asc')
    if f then
      f.stage
    else
      # devolvemos la última stage
      f = self.competitions_matches.find(:first, :conditions => '((participant1_confirmed_result = \'t\' and participant2_confirmed_result = \'t\') or admin_confirmed_result = \'t\')', :order => 'stage desc')
      f.stage
    end
  end
  
  # Comprueba si el usuario especificado es usuario participante o clanleader
  # de algún clan participante.
  def user_is_participant(user_id)
    case self.competitions_participants_type_id
      when 1:
      self.competitions_participants.count(:conditions => ['participant_id = ?', user_id]) > 0
      when 2:
      ids = [0]
      for c in Clan.leaded_by(user_id)
        ids<< c.id
      end
      if ids then
        # first pq solo necesitamos uno
        self.competitions_participants.count(:conditions => "participant_id in (#{ids.join(',')})") > 0
      else
        false
      end
    else
      raise "unimplemented competitions_participants_type_id #{self.competitions_participants_type_id}"
    end
  end
  
  def allowed_participants
    # TODO change this
    if competitions_participants_type_id == 1 then
      User.find(:all, :conditions => "id IN (SELECT participant_id FROM allowed_competitions_participants WHERE competition_id = #{id})", :order => 'lower(login) ASC')
    else
      Clan.find(:all, :conditions => "id IN (SELECT participant_id FROM allowed_competitions_participants WHERE competition_id = #{id})", :order => 'lower(name) ASC')
    end
  end
  
  
  def participants
    # TODO change this
    if competitions_participants_type_id == 1 then
      User.find(:all, :conditions => "id IN (SELECT participant_id FROM competitions_participants WHERE competition_id = #{id})", :order => 'lower(login) ASC')
    else
      Clan.find(:all, :conditions => "id IN (SELECT participant_id FROM competitions_participants WHERE competition_id = #{id})", :order => 'lower(name) ASC')
    end
  end
  
  def find_league_match_between(participant1_id, participant2_id)
    self.competitions_matches.find(:first, :conditions => ['(participant1_id = ? and participant2_id = ?) or (participant1_id = ? and participant2_id = ?)', participant1_id, participant2_id, participant2_id, participant1_id])
  end
  
  
  # private 
  def setup_matches_league(participants=nil)
    # todos contra todos solo ida
    all = participants.nil? ? self.competitions_participants.find(:all, :order => 'position ASC') : participants
    all2 = all.clone
    
    participants_ids = []
    
    for p1 in all
      all2.delete(p1)
      participants_ids<< p1.id
      for p2 in all2
        self.competitions_matches.create({:participant1_id => p1.id, :participant2_id => p2.id, :maps => self.default_maps_per_match})
        participants_ids<< p2.id
      end
    end
    
    participants_ids.uniq! # ya debería ser único, TODO esto meterlo en los tests de competition
    
    # los ordenamos en rondas (jornadas)
    # simplemente vamos iterando a través de todos los partidos y si ninguno de
    # los dos participantes ha jugado en esa jornada asignamos ese partido a la
    # jornada actual.
    #
    # Vamos actuando así hasta acabar con todas las jornadas
    played_in_round = {}
    cur_round = 0
    # recuperamos las partidas que acabamos de crear. Se supone 
    remaining_matches = self.competitions_matches.find(:all, 
                                                       :conditions => "stage = 0 
                                                                   AND (participant1_id IN (#{participants_ids.join(',')}) 
                                                                     OR participant2_id IN (#{participants_ids.join(',')}))")
    while remaining_matches.size > 0
      played_in_round[cur_round] = []
      cp = remaining_matches.clone # clonamos para no modificar el for en el que estamos
      for cm in remaining_matches
        if played_in_round[cur_round].include?(cm.participant1_id) or played_in_round[cur_round].include?(cm.participant2_id)
          next
        end
        cm.stage = cur_round
        cm.save
        # TODO aquí es donde hay que hacer las planificaciones de horas
        cp.delete(cm)
        played_in_round[cur_round]<< cm.participant1_id
        played_in_round[cur_round]<< cm.participant2_id
      end
      
      cur_round += 1
      remaining_matches = cp
    end
  end
  
  def setup_times_for_matches
    if timetable_for_matches == 1 then
      # configuramos las horas a las que se juegan si estamos capacitados para ello
      # necesitamos que nos digan máxima concurrencia
      curday = Competitions::CompetitionsDay.new(timetable_options)
      self.competitions_matches.find(:first, :order => 'stage DESC').stage.times do |jornada|
        for cm in self.competitions_matches.find(:all, :conditions => ['stage = ?', jornada], :order => 'RANDOM() ASC')
          # si le quedan horas para jugar una partida entera al día actual
          # asignamos hoy, si no, avanzamos al día siguiente y la ponemos a primera
          # hora
          curday = curday.next if curday.full?
          curday<< cm
        end
        # TODO asegurarme de que esto no provoca memory leaks
        curday = curday.next # al cambiar de jornada siempre avanzamos
      end
    end
  end
  
  def tourney_classifier_groups
    self.tourney_groups.times.collect do |time|
      Competitions::TourneyClassifierRound.new(self, time)
    end
  end
  
  
  # devuelve el stage (empieza a contar desde 0) en que comienzan las partidas de
  # rondas eliminatorias
  # se tiene que llamar después de haber calculado todas las partidas. si se
  # hace antes no devolverá datos fiables
  def tourney_rounds_starting_stage
    @_cache_tourney_rounds_starting_stage ||= begin
      if self.competitions_types_options[:tourney_use_classifiers] then
        db_query("select max(stage) from competitions_matches WHERE competition_id = #{self.id}")[0]['max'].to_i - self.competitions_types_options[:tourney_rounds].to_i + 1
      else
        0
      end
    end
  end
  
  def matches_can_be_reset?
    self.state >= STARTED && self.state < CLOSED 
  end
  
  def reset_match(cm)
    cm.reset_confirmed_result
    Competitions.recalculate_points(cm.competition)
  end
  
  def total_tourney_rounds
    @_cache_total_tourney_rounds ||= begin
      if self.competitions_types_options[:tourney_use_classifiers] then
        db_query("select max(stage) from competitions_matches WHERE competition_id = #{self.id}")[0]['max'].to_i + 1
      else
        self.tourney_rounds
      end
    end
  end
  
  # jugadores máximos necesarios dependiendo del nivel en el que queremos empezar las eliminatorias
  MATCHES_ON_FIRST_ROUND_PER_TOURNEY_ROUNDS = {1 => 1, 2 => 2, 3 => 4, 4 => 8, 5 => 16, 6 => 32}
  def check_tourney_groups
    # TODO megahack
    return self.competitions_types_options[:tourney_groups].to_i if self.competitions_types_options[:tourney_groups]
    max_participantes_in_phase2 = {3 => 8, 4 => 16, 5 => 32}[self.competitions_types_options[:tourney_rounds].to_i]
    max_winners_per_group = self.competitions_types_options[:tourney_classifiers_rounds].to_i
    max_participantes_in_phase2 / max_winners_per_group # TODO revisar los ceil/floor
  end
  
  # Devuelve número de grupos necesarios para que se generen los jugadores necesarios para llenar el máximo de 
  def tourney_groups
    max_participantes_in_phase2 = {3 => 8, 4 => 16, 5 => 32}[self.competitions_types_options[:tourney_rounds].to_i].to_f
    max_winners_per_group = self.competitions_types_options[:tourney_classifiers_rounds].to_f
     (max_participantes_in_phase2 / max_winners_per_group).ceil
  end
  
  
  def setup_matches_tourney_classifiers
    # TODO aplicar mínimo de participantes según opcions elegidas antes de llegar aquí
    # fase clasificatoria
    # determino 
    groups_count = self.tourney_groups # self.competitions_types_options[:tourney_groups].to_i # self.tourney_groups
    # el grupo (+1) al que pertenece cada participante lo determina el resto de
    # dividir su pos (por id asc) en el torneo entre el número de grupos
    
    groups_participants = {}
    # dividimos a los participantes en sus grupos respectivos
    i = 0
    for p in self.competitions_participants.find(:all, :order => 'position ASC')
      groups_participants[i % groups_count] ||= []
      groups_participants[i % groups_count] << p
      i += 1
    end
    
    # creamos las partidas para los participantes de cada grupo de la fase clasificatoria
    groups_count.times do |group|
      setup_matches_league(groups_participants[group % groups_count])
    end
    
    # NOTA: no usar tourney_rounds_starting_stage ya que esa función tiene en cuenta que YA hemos calculado _todas_ las partidas
    max_stage = db_query("select max(stage) from competitions_matches WHERE competition_id = #{self.id}")[0]['max'].to_i
    setup_matches_tourney([], max_stage + 1, self.competitions_types_options[:tourney_rounds].to_i)
  end
  
  # rounds es el número de rondas de fase eliminatoria
  def setup_matches_tourney(participants=nil, starting_stage=0, rounds=nil)
    all = participants.nil? ? self.competitions_participants.find(:all, :order => 'position ASC') : participants
    rounds = self.tourney_rounds if rounds.nil?
    
    # creamos los slots de combates vacíos
    rounds.times do |stage|
      matches = 2 ** (rounds - stage - 1)
      # nota: matches_this_round tiene los del round anterior
      
      if stage > 0 && ((@matches_this_round / 2.0).ceil < matches) then
        matches = (@matches_this_round / 2.0).ceil
      end
      
      @matches_this_round = 0
      matches.times do |j|
        if stage == 0 then
          if all.size > 0 then
            p1 = all[Kernel.rand(all.size)]
            all.delete(p1)
            if all.size > 0 then
              p2 = all[Kernel.rand(all.size)]
              all.delete(p2)
            else
              p2 = nil
            end
          else
            p1 = p2 = nil
          end
        else
          p1 = p2 = nil
        end # end if stage == 0
        
        # no creamos partidas de stage 0 que tengan p1 = p2 = nil
        if !(p1 == p2 && (starting_stage + stage) == 0) then
          CompetitionsMatch.create({:competition_id => id, :participant1_id => p1.nil? ? nil : p1.id, :participant2_id => p2.nil? ? nil : p2.id, :stage => (starting_stage + stage), :maps => self.default_maps_per_match})
          @matches_this_round += 1
        end
      end # end matches.times
    end # rounds.times
    
    if starting_stage == 0 then # en torneos con clasificatorias no queremos poner valores por defecto a partidas
      for cm in self.competitions_matches.find(:all, :conditions => ['stage = ? and participant2_id is null', starting_stage])
        cm.admin_confirmed_result = true
        cm.result = 0
        cm.save
      end
    end
    
    # TODO no es perfecto
    # buscamos todas las partidas cuyo 2do participante no exista para declarar
    # un ganador automáticamente
    # (rounds - 2).times do |round| # no contamos ni la final ni el stage 0 porque final siempre hay y porque stage0 ya lo hemos tenido en cuenta
    #  for cm in self.competitions_matches.find(:all, :conditions => ['stage = ?', round], :order => 'id DESC')
    #    if cm.participant2_id.nil? then
    #      # tiene 2 participantes
    #    end
    #  end
    # end
  end
  
  def setup_maps_for_matches
    if not (self.default_maps_per_match and self.forced_maps) then
      return
    end
    
    case self.random_map_selection_mode
      when 0: # absolutely random maps
      available_maps = self.games_maps.find(:all, :order => 'lower(name) ASC')
      for cm in self.competitions_matches
        maps_selected = []
        cur_avail_maps = available_maps.clone
        
        cm.maps.times do |time|
          # intentamos hacer lo posible por no repetir mapa en la misma partida
          if cur_avail_maps.size == 0 then
            cur_avail_maps = available_maps.clone
          end
          
          rnd_map = cur_avail_maps[Kernel.rand(cur_avail_maps.size-1)]
          cur_avail_maps.delete(rnd_map)
          cm.competitions_matches_games_maps.create(:games_map_id => rnd_map.id)
        end # cm.maps.times
      end # for cm
      
      when 1:
      available_maps = self.games_maps.find(:all, :order => 'lower(name) ASC')
      tourney_rounds.times do |stage|
        # averiguamos mapas por partida, cargamos una partida de dicho stage
        # por si no tienen el mismo num que tiene la competición
        rnd_cm = self.competitions_matches.find(:first, :conditions => "stage = #{stage}")
        maps_selected = []
        cur_avail_maps = available_maps.clone
        
        rnd_cm.maps.times do |time|
          if cur_avail_maps.size == 0 then
            cur_avail_maps = available_maps.clone
          end
          
          rnd_map = cur_avail_maps[Kernel.rand(cur_avail_maps.size-1)]
          cur_avail_maps.delete(rnd_map)
          for cm in self.competitions_matches.find(:all, :conditions => "stage = #{stage}")
            cm.competitions_matches_games_maps.create(:games_map_id => rnd_map.id)
          end
        end
      end
    else
      raise 'unimplemented'
    end
  end
  
  def tourney_rounds
    @tourney_rounds ||= begin
      participants_size = self.competitions_participants.count
      rounds = 1
      while  2 ** rounds < participants_size
        rounds += 1
      end
      rounds
    end #begin
  end
  
  def user_is_participant_of_match(user_id, match)
    if competitions_participants_type_id == 1 then # check users
     (match.participant1_id and match.participant1.participant_id == user_id) or (match.participant2_id and match.participant2.participant_id == user_id)
    elsif competitions_participants_type_id == 2 then # check clans
      clan1 = Clan.find(:first, :conditions => ['id = ?', match.participant1.participant_id])
      is = false
      if clan1 then 
        is = clan1.user_is_clanleader(user_id)
      end
      
      if not is then
        clan2 = Clan.find(:first, :conditions => ['id = ?', match.participant2.participant_id])
        if clan2 then 
          is = clan2.user_is_clanleader(user_id)
        end
      end
      
      is
    else
      raise 'unimplemented'
    end
  end
  
  # TODO copypasted de arriba
  def user_is_participant1_of_match(user_id, match)
    if competitions_participants_type_id == 1 then # check users
      match.participant1.participant_id == user_id
    elsif competitions_participants_type_id == 2 then # check clans
      clan1 = Clan.find(:first, :conditions => ['id = ?', match.participant1.participant_id])
      if clan1 then 
        clan1.user_is_clanleader(user_id)
      end
    else
      raise 'unimplemented'
    end
  end
  
  def can_be_deleted?
    state < Competition::STARTED || competitions_matches.count == 0
  end
  
  def self.find_by_admin(u)
    # u.users_roles.find(:all, :conditions => 'role = \'CompetitionAdmin\'').collect { |ur| Competition.find(ur.role_data.to_i)}
    Competition.find(:all, :conditions => "id IN (SELECT role_data::int4 FROM users_roles WHERE user_id = #{u.id} AND role = 'CompetitionAdmin')", :order => 'lower(name)')
  end
  
  def self.find_by_supervisor(u)
    Competition.find(:all, :conditions => "id IN (SELECT role_data::int4 FROM users_roles WHERE user_id = #{u.id} AND role = 'CompetitionSupervisor')", :order => 'lower(name)')
  end
end
