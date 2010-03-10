require 'digest/md5'
require 'karma'

class User < ActiveRecord::Base
  BANNED_DOMAINS = %w(fishfuse.com 10minutemail.com correo.nu tempinbox.com mintemail.uni.cc yopmail.com uggsrock.com tempemail.net)
  
  ANTIFLOOD_LEVELS = {
    1 => 'suave',
    2 => 'moderado',
    3 => 'duro',
    4 => 'extremo',
    5 => 'absoluto'}
  
  ST_UNCONFIRMED = 0
  ST_ACTIVE = 1
  ST_ZOMBIE = 2
  ST_RESURRECTED = 3
  ST_SHADOW = 4
  ST_BANNED = 5
  ST_DISABLED = 6
  ST_DELETED = 7
  ST_UNCONFIRMED_1W = 8
  ST_UNCONFIRMED_2W = 9
  
  HSTATES = %w(unconfirmed active zombie resurrected shadow banned disabled deleted)
  STATES_CAN_LOGIN = [ST_ACTIVE, ST_ZOMBIE, ST_RESURRECTED, ST_SHADOW]
  STATES_CANNOT_LOGIN = [ST_UNCONFIRMED, ST_BANNED, ST_DISABLED, ST_DELETED, ST_UNCONFIRMED_1W, ST_UNCONFIRMED_2W]
  
  STATES_DESCRIPTIONS = {ST_UNCONFIRMED => 'no confirmada',
    ST_BANNED => 'baneada',
    ST_DISABLED => 'deshabilitada',
    ST_DELETED => 'borrada',
    ST_UNCONFIRMED_1W => 'no confirmada',
    ST_UNCONFIRMED_2W => 'no confirmada'}
  has_many :groups_messages
  
  has_many :users_roles, :dependent => :destroy
  has_many :friends_recommendations
  has_many :clans_movements
  has_many :recruitment_ads
  has_many :users_emblems
  has_many :factions_banned_users
  has_many :comment_violation_opinions
  has_many :preferences, :class_name => 'UsersPreference'
  belongs_to :country
  belongs_to :faction
  belongs_to :avatar
  belongs_to :referer, :class_name => 'User', :foreign_key => 'referer_user_id'
  belongs_to :resurrector, :class_name => 'User', :foreign_key => 'resurrected_by_user_id'
  belongs_to :comments_valorations_type  
  has_many :comments_valorations
  has_many :users_contents_tags
  
  has_many :profile_signatures
  has_one :filter
  has_many :polls_votes
  belongs_to :requests_to_be_banned, :class_name => 'User', :foreign_key => 'banned_user_id'
  belongs_to :confirmed_ban_requests, :class_name => 'User', :foreign_key => 'confirming_user_id'
  has_many :ban_requests
  has_many :skins
  has_many :sold_products
  has_many :gmtv_channels
  has_many :chatlines
  has_many :content_ratings
  has_many :contents
  has_many :publishing_personalities
  has_many :publishing_decisions
  has_many :tracker_items
  has_many :user_login_changes
  has_many :users_newsfeeds
  #  has_many :friends, :through => :friendships  
  # has_and_belongs_to_many :friends
  file_column :photo
  file_column :competition_roster
  belongs_to :last_clan, :class_name => 'Clan', :foreign_key => 'last_clan_id'
  has_and_belongs_to_many :events
  has_many :avatars
  
  # contents
  has_many :news
  has_many :topics
  has_many :downloads
  has_many :bets
  has_many :images
  has_many :events
  has_many :coverages
  has_many :polls
  has_many :tutorials
  has_many :columns
  has_many :demos
  has_many :interviews
  has_many :reviews
  has_many :funthings
  has_many :comments
  has_many :blogentries
  has_many :questions
  
  has_and_belongs_to_many :games
  has_and_belongs_to_many :platforms
  
  has_many :users_guids
  
  has_many :messages_sent, :foreign_key => 'user_id_from', :class_name => 'Message'
  has_many :messages_received, :foreign_key => 'user_id_to', :class_name => 'Message'
  
  has_many :contents_recommendations, :foreign_key => 'receiver_user_id'
  has_many :contents_recommended, :foreign_key => 'sender_user_id'
  
  has_many :autologin_keys
  
  has_bank_account
  before_save :update_rosters
  before_save :check_rating_slots
  before_save :check_homepage
  before_save :check_lastcommented_on
  before_save :check_age
  
  after_save :update_competition_name
  after_save :check_is_hq
  after_save :check_login_changed
  after_save :check_permissions
  observe_attr :competition_roster, :login, :state, :is_hq, :faction_id, :lastcommented_on, :avatar_id, :photo, :homepage
  
  before_create :generate_validkey
  after_create :change_avatar
  attr_accessor :ident, :expire_at
  attr_protected :cache_karma_points, :is_superadmin, :admin_permissions, :faction_id
  
  before_save :check_if_shadow
  before_save :check_if_website
  
  named_scope :can_login, :conditions => "state IN (#{STATES_CAN_LOGIN.join(',')})", :order => 'lower(login)'
  named_scope :humans, :conditions => 'is_bot is false'
  
  def can_login?
    STATES_CAN_LOGIN.include?(self.state)   
  end
  
  def check_if_shadow
    self.state = ST_SHADOW if self.state == ST_ZOMBIE && self.lastseen_on > 1.minute.ago
    true
  end
  
  def ne_references
    NeReference.find(:all, :conditions => ['(entity_class = \'User\' AND entity_id = ?)', self.id])  
  end
  
  def check_if_website
    return unless self.slnc_changed?(:homepage)
    
    if self.homepage.to_s != '' 
      if !(Cms::URL_REGEXP_FULL =~ self.homepage)
        self.homepage  = "http://#{self.homepage}"
        Cms::URL_REGEXP_FULL =~ self.homepage
      else
        true
      end
    else
      true
    end
  end
  
  
  def ban_reason
    self.pref_public_ban_reason != '' ? self.pref_public_ban_reason : 'Desconocida'
  end
  
  
  def latent_rating(c)
    cr = self.content_ratings.find_by_content_id(c.id)
    if cr
      cr.rating
    else
      comments_count = c.comments.count(:conditions => ['user_id = ?', self.id])
      if comments_count = 0
        5.5
      else    
        comments_count = 5 if comments_count > 5
        5 + comments_count
      end     
    end     
  end
  
  def contents_visited_between(t1, t2)
    self.tracker_items.find(:all, :conditions => ['lastseen_on BETWEEN ? AND ?', t1, t2], :include => :content).collect { |ti| ti.content } || []
  end
  
  def check_permissions
    [self.users_roles.find_by_role('Boss'), self.users_roles.find_by_role('Underboss')].compact.each do |ur|
      ur.destroy
    end if slnc_changed?(:faction_id)
    
    self.users_roles.clear if slnc_changed?(:state) && STATES_CANNOT_LOGIN.include?(self.state)
  end
  
  def check_login_changed
    GmSys.job("Blogentry.reset_urls_of_user_id(#{self.id})") if slnc_changed?(:login)
    true
  end
  
  def impose_antiflood(level, impositor)
    level = 0 if level < -1 || level > 5
    self.antiflood_level = level
    return false unless self.save
    
    # TODO This should go into an observer
    if impositor.has_admin_permission?(:capo)
      SlogEntry.create(:type_id => SlogEntry::TYPES[:emergency_antiflood], :reporter_user_id => impositor.id, :headline => "Antiflood #{User::ANTIFLOOD_LEVELS[self.antiflood_level]} impuesto a <strong><a href=\"#{ApplicationController.gmurl(self)}\">#{self.login}</a></strong> por <a href=\"#{ApplicationController.gmurl(impositor)}\">#{impositor.login}</a>")
    else
      SlogEntry.create(:type_id => SlogEntry::TYPES[:emergency_antiflood], :reporter_user_id => impositor.id, :headline => "Antiflood de emergencia impuesto a <strong><a href=\"#{ApplicationController.gmurl(self)}\">#{self.login}</a></strong> por <a href=\"#{ApplicationController.gmurl(impositor)}\">#{impositor.login}</a>")
    end
    true
  end
  
  def get_comments_valorations_type
    check_comments_values
    # recalcula en caso de ser nulo
    self.comments_valorations_type
  end
  
  def get_comments_valorations_strength
    check_comments_values
    self.comments_valorations_strength
  end
  
  
  def check_is_staff
    # actualiza la variable is_staff
    is_staff = self.users_roles.count(:conditions => "role IN ('Don', 'ManoDerecha', 'Sicario', 'Moderator', 'Editor', 'Boss', 'Underboss')") > 0 || has_admin_permissions? || is_competition_admin? || is_competition_supervisor?
    self.update_attributes(:is_staff => is_staff, :cache_is_faction_leader => self._no_cache_is_faction_leader?)
  end
  
  def check_comments_values
    if self.comments_valorations_strength.nil? || self.comments_valorations_type_id.nil? then
      d = Comments.get_user_type_based_on_comments(self)
      self.comments_valorations_strength = d[1]
      self.comments_valorations_type_id = d[0].id
      self.save
    end
  end
  
  def valorations_on_self_comments
    User.db_query("SELECT count(*) as count
                     FROM comments_valorations                     
           JOIN comments on comments_valorations.comment_id = comments.id
                    WHERE comments.user_id = #{self.id}")[0]['count'].to_i
  end
  
  def valorations_weights_on_self_comments
    if self.cache_valorations_weights_on_self_comments.nil?
      self.update_attributes(:cache_valorations_weights_on_self_comments => User.db_query("SELECT sum(weight) as sum
                     FROM comments_valorations                     
           JOIN comments on comments_valorations.comment_id = comments.id
                    WHERE comments.user_id = #{self.id}")[0]['sum'].to_f)
    end
    self.cache_valorations_weights_on_self_comments
  end
  
  def method_missing(method_id, *args)
    smethod_id = method_id.to_s
    if /pref_([a-z0-9_]+)$/ =~ smethod_id
      pref_name = smethod_id.gsub('pref_', '')
      pref = self.preferences.find_by_name(pref_name)
      if pref.nil?
        final = UsersPreference::DEFAULTS[pref_name.to_sym]
        final = final.new if final.class.name == 'Class'
      else
        final = pref.value
      end
      final
    elsif /pref_([a-z0-9_]+)=$/ =~ smethod_id
      # saving preference
      pref_name = smethod_id.gsub('pref_', '').gsub('=', '')
      pref = self.preferences.find_by_name(pref_name)
      if pref.nil?
        self.preferences.create(:name => pref_name, :value => args[0])
      else
        pref.update_attributes(:value => args[0])
      end
    else
      super
    end
  end
  
  def respond_to?(method_id, include_priv = false)
    smethod_id = method_id.to_s
    if /pref_([a-z0-9_]+)$/ =~ smethod_id
      true
    elsif /pref_([a-z0-9_]+)=$/ =~ smethod_id
      true
    else
      super
    end
  end  
  
  def check_is_hq
    if slnc_changed?(:is_hq) && self.is_hq?
      require 'open-uri'
      valid_username = self.login.bare
      q_auth = "&os_username=#{App.jira_username}&os_password=#{App.jira_password}"
      
      contents = open("http://hq.gamersmafia.com/secure/admin/user/ViewUser.jspa?name=#{valid_username}#{q_auth}", OPENURI_HEADERS).read
      
      if contents.include?('User does not exist') # let's go!
        #puts "creating account at jira"
        open("http://hq.gamersmafia.com/secure/admin/user/AddUser.jspa?username=#{valid_username}&fullname=#{valid_username}&email=#{self.email}&sendEmail=true&Crear=Crear#{q_auth}", OPENURI_HEADERS).read
        ['GM+HQ', 'confluence-users'].each do |g|
          open("http://hq.gamersmafia.com/secure/admin/user/EditUserGroups.jspa?join=Join+%3E%3E&groupsToJoin=#{g}&name=#{valid_username}#{q_auth}", OPENURI_HEADERS)
        end
      end
      # TODO enviar mp con info y bienvenida
      Notification.deliver_add_to_hq(User.find(1), :new_member => self)
      # Notification.deliver_welcome_to_hq(self)
      Message.create(:sender => User.find(1), :recipient => self, :title => "¡Bienvenido al HQ!", :message => "Ya te he dado de alta en el HQ.\n\nTe recomiendo que para empezar vayas al wiki (menú horizontal encima de la cabecera HQ -> Wiki) ya que hay un información sobre cómo usar tanto el wiki como jira y la lista de correo interna.. \n\nTe debería haber llegado un email con un nombre de usuario y una contraseña, son para acceder al wiki y al gestor de incidencias (JIRA). En el wiki verás varias zonas con toda la información sobre wiki y gestor de incidencias y sobre la lista de correo. Te recomiendo empezar por esta pagina: http://hq.gamersmafia.com/confluence/display/GM/Bienvenido+a+Gamersmafia y tener bien claro esta otra: http://hq.gamersmafia.com/confluence/display/GM/Netiqueta+para+miembros+del+HQ. Por favor, échales un vistazo (por supuesto no hay prisa, cuando puedas) y si tienes alguna duda puedes preguntar tanto en la lista interna como por privado.\n\nUn saludete :D")
      #old_email = self.email
      #self.email = 'ayuda-form@gamersmafia.com'
      #is_hq? ? Notification.deliver_add_to_hq(self) : Notification.deliver_del_from_hq(self)
      #self.email = old_email
    elsif slnc_changed?(:is_hq) # dando de baja del hq
      # TODO dar de baja del hq
      ['jira-users', 'GM+HQ', 'confluence-users'].each do |g|
        contents = open("http://hq.gamersmafia.com/secure/admin/user/EditUserGroups.jspa?leave=%3C%3C+Leave&groupsToLeave=#{g}&name=#{valid_username}&returnUrl=UserBrowser.jspa#{q_auth}", OPENURI_HEADERS)
      end
    end
  end
  
  def _no_cache_is_faction_leader?
   (!self.faction_id.nil?) && (self.has_admin_permission?(:capo) || self.users_roles.count(:conditions => "role IN ('Boss', 'Underboss')") > 0)
  end
  
  def is_faction_leader?
    self.cache_is_faction_leader
  end
  
  def is_district_leader?
    self.has_admin_permission?(:bazar_manager) || UsersRole.count(:conditions => ["role IN ('#{BazarDistrict::ROLE_DON}', '#{BazarDistrict::ROLE_MANO_DERECHA}') AND user_id = ?", self.id]) > 0
  end
  
  def check_homepage
    if self.homepage.to_s != '' and not (self.homepage =~/^http:/) then
      self.homepage = ('http://' << self.homepage)
    end
  end
  
  def self.online(order='faction_id asc, lastseen_on desc')
    User.find(:all, :conditions => 'lastseen_on >= now() - \'30 minutes\'::interval', :order => order, :limit => 100)
  end
  
  def banned # TODO remove this
    self.state == User::ST_BANNED
  end
  
  def disabled # TODO remove this
    self.state == User::ST_DISABLED
  end
  
  def self.online_count
    self.count(:conditions => "lastseen_on >= now() - '30 minutes'::interval and state <> #{User::ST_UNCONFIRMED}")
  end
  
  def self.find_by_autologin_key(k)
    akey = AutologinKey.find_by_key(k)
    
    if akey
      User.db_query("update users set lastseen_on = now() where id = #{akey.user_id}")
      akey.update_attributes(:lastused_on => Time.now)
      akey.user
    end
  end
  
  ADMIN_PERMISSIONS_INDEXES = {:faq => 0, :blogs => 1, :clans => 2, :avatars => 3, :faction_headers => 4, :capo => 5, :designer => 6, :qa => 7, :fusions => 8, :gladiador => 9, :advertiser => 10, :bazar_manager => 11}
  
  def self.find_with_admin_permissions(args)
    if args.kind_of?(Symbol)
      args = [ADMIN_PERMISSIONS_INDEXES[args]]
    elsif args.kind_of?(Hash) && args[0].kind_of?(Symbol)
      args = args.collect { |a| ADMIN_PERMISSIONS_INDEXES[a] }
    end
    
    # args tiene que valer ahora
    s = ''
    args.each do |a|
      s<< ('_'*a) if a > 0
      s<< '1%'
    end
    User.find(:all, :conditions => "admin_permissions LIKE '#{s}'")
  end
  
  def has_admin_permissions?
    self.admin_permissions.to_i > 0
  end
  
  def has_admin_permission?(permission)
    #is_superadmin || (admin_permissions.size >= (User::ADMIN_PERMISSIONS_INDEXES[permission.to_sym] - 1) && admin_permissions[User::ADMIN_PERMISSIONS_INDEXES[permission.to_sym]..User::ADMIN_PERMISSIONS_INDEXES[permission.to_sym]] == '1')
    is_superadmin || admin_permissions[User::ADMIN_PERMISSIONS_INDEXES.fetch(permission.to_sym)..User::ADMIN_PERMISSIONS_INDEXES.fetch(permission.to_sym)] == '1'
  end
  
  def give_admin_permission(permission)
    if self.admin_permissions.size < User::ADMIN_PERMISSIONS_INDEXES[permission]
      self.admin_permissions << '0'*(User::ADMIN_PERMISSIONS_INDEXES.size - self.admin_permissions.size) 
    end
    self.admin_permissions[User::ADMIN_PERMISSIONS_INDEXES[permission]] = '1'
    self.save
  end
  
  def take_admin_permission(permission)
    self.admin_permissions[User::ADMIN_PERMISSIONS_INDEXES[permission]] = '0'
    self.save
  end
  
  def update_admin_permissions(new_permissions)
    self.admin_permissions = new_permissions
    save
  end
  
  def self.find_by_login(login)
    self.find(:first, :conditions => ['lower(login) = lower(?)', login.to_s])
  end
  
  def self.find_by_login!(login)
    self.find_by_login(login) || (raise ActiveRecord::RecorNotFound)
  end
  
  def self.find_by_email(email)
    self.find(:first, :conditions => ['lower(email) = lower(?)', email])
  end
  
  # Busca un usuario que se corresponda con el username y el password indicados
  def self.login(username, password)
    u = find(:first, :conditions => ['lower(login) = lower(?) AND password = ?', username, Digest::MD5.hexdigest(password)])
    
    if u then
      #u.db_query("update users set lastseen_on = now() where id = #{u.id}")
      #u.lastseen_on = Time.now # perf: da igual que haya una diferencia entre
      # el lastseen_on de db y el del modelo
    end
    u
  end
  
  def clearpasswd(password)
    Digest::MD5.hexdigest(password)
  end
  
  
  public
  def get_new_autologin_key
    require 'digest/sha1'
    newkey = Digest::SHA1.hexdigest((Kernel.rand(1000000).to_i + self.id.to_i + Time.now.to_i).to_s + self.login)
    
    while AutologinKey.find_by_key(newkey)
      newkey = Digest::SHA1.hexdigest((Kernel.rand(1000000).to_i + self.id.to_i + Time.now.to_i).to_s + self.login)
    end
    
    akey = AutologinKey.new({:user_id => self.id, :key => newkey, :lastused_on => Time.now})
    if akey.save then
      akey.key
    end
  end
  
  def update_competition_name
    if self.slnc_changed?(:login)
      for cp in CompetitionsParticipant.find(:all, :conditions => ['competition_id IN (select id from competitions WHERE state < 4 and competitions_participants_type_id = 1) and participant_id = ?', self.id])
        cp.name = self.login
        cp.save
      end
    end
  end
  
  def update_rosters
    if self.slnc_changed?(:competition_roster)
      for cp in CompetitionsParticipant.find(:all, :conditions => ['competition_id IN (select id from competitions WHERE state < 4 and competitions_participants_type_id = 1) and participant_id = ?', self.id])
        cp.roster = nil
        cp.save
      end
    end
  end
  
  
  # TODO esto no va en esta clase
  def clans
    # TODO cambiar permisos de clanes
    # TODO cachear
    Clan.find_by_sql("SELECT * 
                        FROM clans 
                       WHERE id IN (SELECT a.clan_id 
                                      FROM clans_groups a 
                                      JOIN clans_groups_users b on a.id = b.clans_group_id 
                                     WHERE b.user_id = #{self.id}) 
                    ORDER BY lower(name) ASC")
  end
  
  def clans_ids
    User.db_query("select a.clan_id from clans_groups a join clans_groups_users b on a.id = b.clans_group_id where b.user_id = #{self.id}").collect { |dbr| dbr['clan_id'].to_i }
  end
  
  def get_secret
    if self.secret.to_s == '' then
      s = self.class.md5(Kernel.rand.to_s)
      
      while User.find(:first, :conditions => ['lower(secret) = lower(?)', s])
        s = self.class.md5(Kernel.rand.to_s)
      end
      
      self.secret = s
      self.save
    end
    
    self.secret
  end
  
  def can_change_faction?
    time_1_month_ago = Time.at(Time.now - 86400 * 30)
    
    if self.faction_last_changed_on.nil? or (self.faction_last_changed_on < time_1_month_ago) then
      true
    else
      false
    end
  end
  
  def is_bigboss?
   (self.users_roles.count(:conditions => "role IN ('Boss', 'Underboss', 'Don', 'ManoDerecha')") > 0) || self.has_admin_permission?(:bazar_manager) || self.has_admin_permission?(:capo) || self.is_superadmin 
  end
  
  def is_faction_editor?
    is_faction_leader? || self.users_roles.count(:conditions => "role = 'Editor'") > 0 || has_admin_permission?(:capo)
  end
  
  def is_editor?
    
    # TODO cachear
    # devuelve true si el usuario puede editar algún tipo de contenido
    if self.is_bigboss?
      true
    elsif self.users_roles.count(:conditions => 'role IN (\'CompetitionAdmin\', \'CompetitionSupervisor\')') > 0
      true
    elsif self.users_roles.count(:conditions => "role = 'Editor'") > 0
      true
    else
      false
    end
  end
  
  def is_moderator?
    self.is_faction_leader? || self.users_roles.count(:conditions => "role = 'Moderator'") > 0
  end
  
  def is_competition_admin?
    has_admin_permission?(:gladiador) || self.users_roles.count(:conditions => "role = 'CompetitionAdmin'") > 0
  end
  
  def is_competition_supervisor?
    has_admin_permission?(:gladiador) || is_competition_admin? || self.users_roles.count(:conditions => "role = 'CompetitionSupervisor'") > 0
  end
  
  def is_sicario?
    self.is_district_leader? || self.users_roles.count(:conditions => "role = 'Sicario'") > 0
  end
  
  def unread_messages
    self.cache_unread_messages = Message.update_unread_count(self) if self.cache_unread_messages.nil?    
    self.cache_unread_messages
  end
  
  def is_friend_of?(user)
    # si self está en la lista de amigos de user devuelve true
    f = Friendship.find_between(self, user)
     (f && f.accepted_on) ? true : false
  end
  
  def remaining_rating_slots
    if self.cache_remaining_rating_slots.nil?
      self.cache_remaining_rating_slots = Faith.max_daily_ratings(self) - self.content_ratings.count(:conditions => 'created_on >= date_trunc(\'day\', now())') - self.comments_valorations.count(:conditions => 'created_on >= date_trunc(\'day\', now())')
      User.db_query("UPDATE users SET cache_remaining_rating_slots = #{self.cache_remaining_rating_slots} WHERE id = #{self.id}")
      raise "Error updating remaining_rating_slots" if self.cache_remaining_rating_slots.nil? 
    end
    self.cache_remaining_rating_slots < 0 ? 0 : self.cache_remaining_rating_slots 
  end
  
  def can_rate?(content)
    if content.user_id == self.id || remaining_rating_slots == 0 || ContentRating.count(:conditions => ['content_id = ? and user_id = ?', content.unique_content.id, self.id]) > 0 
      false
    else
      true
    end
  end
  
  def can_change_faction_after
    time_activate_again = Time.at(self.faction_last_changed_on + 86400 * 30)
  end
  
  def tracker_empty?
    return TrackerItem.count(:conditions => ['user_id = ? and is_tracked = \'t\'', self.id]) == 0 ? true : false
  end
  
  def tracker_has?(object_id)
    TrackerItem.count(:conditions => ['content_id = ? and user_id = ? and is_tracked = \'t\'', object_id, self.id]) == 1
  end
  
  def change_avatar(new_avatar_id=nil)
    if new_avatar_id
      av = Avatar.find(new_avatar_id)
      raise AccessDenied unless av.is_available_for_user(self)  
    end
    
    self.avatar_id = new_avatar_id
    self.save
  end
  
  def show_avatar
    if self.state == User::ST_BANNED
      "/images/banned.jpg"
    elsif self.avatar_id && self.avatar.path
      "/#{self.avatar.path}"
    else
      "/images/default_avatar.jpg"
    end
  end
  
  def show_photo
    if self.state == User::ST_BANNED
      "/images/banned.jpg"
    elsif self.photo && self.photo != ''
      "/#{self.photo}"
    else
      "/images/default_avatar.jpg"
    end
  end
  
  def faith_points
    if self.cache_faith_points.nil? then
      self.update_attribute('cache_faith_points', Faith::calculate_faith_points(self))
    end
    
    self.cache_faith_points
  end
  
  def karma_points
    if self.cache_karma_points.nil? then
      self.cache_karma_points = db_query("UPDATE users SET cache_karma_points = #{Karma::calculate_karma_points(self)} WHERE id = #{self.id} AND cache_karma_points is null; SELECT cache_karma_points FROM users WHERE id = #{self.id}")[0]['cache_karma_points'] 
    end
    
    self.cache_karma_points
  end
  
  def popularity_points
    self.cache_popularity
  end
  
  def karma_points_editor
    # devuelve el numero de puntos de karma acumulados por editar contenidos
    total = 0
    for c in Karma::KPS_SAVE
      begin
        total += Object.const_get(c[0]).count(:conditions => ["approved_by_user_id = ? and state = #{Cms::PUBLISHED}", self.id]) * c[1]
      rescue:
        raise c[0]
      end
    end
    total
  end
  
  def self.md5(txt)
    Digest::MD5.hexdigest(txt)
  end
  
  def upload_file(tmpfile)
    d = "#{RAILS_ROOT}/public/storage/users_files/#{(self.id/1000).to_i}/#{self.id}/"   
    FileUtils.mkdir_p(d) unless File.exists?(d)
    
    preppend = ''
    if tmpfile.respond_to?('original_filename') then
      filename = tmpfile.original_filename
    else
      filename = File.basename(tmpfile.path)
    end
    
    filename = filename.gsub('..', '').gsub('/', '')
    
    while File.exists?("#{d}#{preppend}#{filename}") 
      preppend = "_#{preppend}"
    end
    
    require 'fileutils'
    if tmpfile.respond_to?('path') and tmpfile.path then
      FileUtils::cp(tmpfile.path, "#{d}#{preppend}#{filename}")
    else
      File.open("#{d}#{preppend}#{filename}", 'w+') { |f| f.write(tmpfile.read()) }
    end
  end
  
  def get_tmp_basedir
    d = "/storage/users_files/#{(self.id/1000).to_i}/#{self.id}/"
  end
  
  def del_my_file filename
    # TODO revisar esto
    for f in self.get_my_files
      if f == filename then
        File.unlink("#{RAILS_ROOT}/public/storage/users_files/#{(self.id/1000).to_i}/#{self.id}/#{f}")
        break
      end
    end
  end
  
  def get_my_files
    d = "#{RAILS_ROOT}/public/storage/users_files/#{(self.id/1000).to_i}/#{self.id}/"
    
    if not File.exists?(d) then
      FileUtils.mkdir_p d
    end
    
     (Dir.entries(d) - %w(.. .)).sort
  end
  
  def resurrect
    # método llamado cuando un usuario en modo resurreción incompleta inicia sesión
    Faith.reset(self.resurrector)
    Notification.deliver_resurrection(resurrector, {:resurrected => self})
  end
  
  def contents_stats
    res = {}
     (Cms.contents_classes + [Blogentry]).each do |cls|
      res[Cms.translate_content_name(cls.name).titleize] = self.send(ActiveSupport::Inflector::tableize(cls.name)).count(:conditions => "state = #{Cms::PUBLISHED}")
    end
    res['Comentarios'] = self.comments_count
    res
  end
  
  def to_s
    login
  end
  
  # Devuelve la edad del usuario o nil si no ha especificado
  def age(today=DateTime.now)
    return if self.birthday.nil?
    
    if today.month > self.birthday.month || \
     (today.month == self.birthday.month && today.day >= self.birthday.day) then # ya ha sido tu cumpleaños o es hoy
      today.year - self.birthday.year
    else # todavía no ha pasado el cumpleaños
      today.year - self.birthday.year - 1
    end
  end
  
  def check_age
    if self.birthday == nil
      return true
    end
    
    if DateTime.now.year - self.birthday.year >= 3 && DateTime.now.year - self.birthday.year <= 130 then
      true
    else
      self.errors.add('birthday','Error: Fecha de cumpleaños no válida. Se debe introducir una edad entre 4 y 130 años.')
      false  
    end
    
  end
  
  # Before creating, we generate a validkey.
  # This is used for confirmation
  def generate_validkey
    self.validkey = Digest::MD5.hexdigest(self.login + AccountHelper::Utils::random_string(30))
  end
  
  def hstate
    HSTATES[self.state]
  end
  
  
  # Devuelve la fecha aproximada de última actividad del usuario en base al último comentario que publicó.
  def first_activity
    c = self.comments.find(:first, :order => 'created_on ASC')
    c ? c.created_on : self.created_on
  end
  
  def change_internal_state(new_state)
    self.update_attributes(:state => User.const_get("ST_#{new_state.to_s.normalize.upcase}"))
  end
  
  
  def start_resurrection(resurrector)
    if self.state == User::ST_ZOMBIE and not (self.resurrected_by_user_id and self.resurrection_started_on > Time.now - 86400 * 7) and Faith.resurrections_incomplete(resurrector) < Faith.max_incomplete_resurrections(resurrector) then
      #raise self.update_attributes({:resurrected_by_user_id => resurrector.id, :resurrection_started_on => Time.now}).to_s
      self.resurrected_by_user_id = resurrector.id
      self.resurrection_started_on = Time.now
      self.save
    end
  end
  
  protected
  def password=(clearpasswd)
    if clearpasswd.to_s != ''
        self['password'] = Digest::MD5.hexdigest(clearpasswd) 
        self.generate_validkey
    end
  end
  
  def is_online
    time1 = Time.now
    time_25_min_ago = Time.local(time1.year, time1.month, time1.day, time1.hour, time1.min - 25, time1.sec)
    return time_25_min_ago > time1
  end
  
  
  validates_confirmation_of :password, :message => ' no coinciden'
  validates_confirmation_of :email, :message => ' no coinciden'
  
  validates_uniqueness_of :login, :on => :create, :message => ' login duplicado. Debes elegir un login distinto'
  validates_uniqueness_of :login, :on => :update, :message => ' login duplicado. Debes elegir un login distinto'
  validates_uniqueness_of :email, :on => :create, :message => ' email duplicado. Debes elegir un email distinto'
  validates_uniqueness_of :email, :on => :update, :message => ' email duplicado. Debes elegir un email distinto'
  validates_uniqueness_of :validkey, :on => :create, :message => ' error interno'
  
  #validates_confirmation_of :password
  validates_length_of :login, :within => 3..31
  validates_length_of :password, :minimum => 6, :allow_nil => true
  validates_length_of :email, :maximum=> 100
  validates_length_of :ipaddr, :maximum => 15
  validates_length_of :validkey, :maximum => 40, :allow_nil => true # TODO 30 May 07: añadir not null constraint cuando te vuelva a ver
  
  # TODO no permitir registrar el usuario banco
  validates_length_of :firstname, :maximum => 40, :allow_nil => true
  validates_length_of :lastname, :maximum => 40, :allow_nil => true
  validates_length_of :comments_sig, :maximum => 70, :allow_nil => true
  validates_uniqueness_ignoring_case_of :login, :email, :comments_sig
  
  validates_presence_of :login, :email, :ipaddr
  
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[A-Za-z]{2,})$/
  validates_format_of :newemail, :with => /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[A-Za-z]{2,})$/, :allow_nil => true
  LOGIN_REGEXP = /^[-a-zA-Z0-9_~.\[\]\(\)\:=|*^]{3,18}$/
  INVALID_LOGIN_CHARS = 'Caracteres válidos: a-z A-Z 0-9 _-.[]():=|*^'
  validates_format_of :login, :with => LOGIN_REGEXP, :on => :create, :message => INVALID_LOGIN_CHARS # TODO forzar estas restricciones a cuentas existentes
  
  def check_lastcommented_on
    if [ST_SHADOW, ST_ZOMBIE].include?(state) && slnc_changed?(:lastcommented_on) && self.lastcommented_on && self.lastcommented_on > 3.months.ago
      self.state = ST_ACTIVE
    end
  end
  # NOTA: esto debe estar aquí para que validates_confirmation_of no nos machaque
  def password_confirmation=(clearpasswd)
    @password_confirmation = Digest::MD5.hexdigest(clearpasswd) unless clearpasswd.to_s == ''
  end
  
  def check_rating_slots
    self.cache_remaining_rating_slots = nil if self.cache_remaining_rating_slots && self.cache_remaining_rating_slots < 0
    true
  end
  
  def self.top_profile_hits
    raise "TODO"
    # "select count(distinct(visitor_id)), (select login from users where id = stats.pageviews.model_id::integer) from stats.pageviews where controller = 'miembros' and action = 'member' and created_on >= now() - '1 month'::interval group by model_id order by count(distinct(visitor_id)) desc limit 10;
    
  end
  
  def self.hot(limit, t1, t2)
    t1, t2 = t2, t1 if t1 > t2
    # TODO PERF no podemos hacer esto, dios, hay que calcular esta info en segundo plano y solo leerla
    dbi = Dbs.db_query("select count(distinct(visitor_id)), 
                                model_id 
                           from stats.pageviews 
                          where controller = 'miembros' 
                            and action = 'member' 
                            and created_on BETWEEN '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}' 
                            and model_id not in (select id::varchar 
                                                   from users 
                                                  where state in (#{STATES_CANNOT_LOGIN.join(',')})) 
                       group by model_id 
                       order by count(distinct(visitor_id)) desc 
                          limit #{limit}")
    results = []
    dbi.each do |dbu|
      u = User.find_by_id(dbu['model_id'].to_i)
      next unless u
      results<< [u, dbu['count'].to_i]
    end
    results
  end
  
  public
  def disable_all_email_notifications
    self.update_attributes(:send_global_announces => false,
                           :notifications_global => false,
                           :notifications_newregistrations => false,
                           :notifications_newmessages => false,
                           :notifications_trackerupdates => false
    )
    self.save
    Message.create(:sender => User.find_by_login('nagato'), :recipient => self, :title => 'Notificaciones desactivadas', :message => "Hola, he desactivado el envío de todas las notificaciones por email a tu cuenta ya que estamos recibiendo errores de tu servidor de correo. Si crees que esto es un error por favor mandale un mensaje a [~slnc].\n\nPuedes reactivar las notificaciones en la sección [url=http://gamersmafia.com/cuenta]Mi cuenta[/url]")
  end
  # TODO no contabilizar usuarios baneados en amistades
  # TODO pensar este algoritmo
  def self.most_friends(limit=10)
    User.db_query("select sender_user_id,
                          count(*) as total_friends_from,
                          (select count(*) 
                             from friendships 
                            where receiver_user_id = a.sender_user_id 
                              and accepted_on is not null 
                              and sender_user_id not in (select id 
                                                           from users 
                                                          where state IN (#{User::STATES_CANNOT_LOGIN.join(', ')}))) as total_friends_to
                     from friendships as a
                    where accepted_on is not null
                      AND receiver_user_id not in (select id 
                                                           from users 
                                                          where state IN (#{User::STATES_CANNOT_LOGIN.join(', ')}))
                 group by sender_user_id
                 order by count(*) + (select count(*) 
                                        from friendships 
                                       where receiver_user_id = a.sender_user_id 
                                         and accepted_on is not null 
                                         and sender_user_id not in (select id 
                                                                      from users 
                                                                     where state IN (#{User::STATES_CANNOT_LOGIN.join(', ')}))) desc 
                    limit #{limit}").collect { |dbu|
      
      {:user => User.find(dbu['sender_user_id'].to_i), :friends => dbu['total_friends_from'].to_i + dbu['total_friends_to'].to_i }
    }
  end
  
  def confirm_tasks
    # se ejecuta cuando un usuario confirma su cuenta
    self.state = User::ST_SHADOW
    self.save
    Notification.deliver_newregistration(User.find(self.referer_user_id), { :refered => self }) if self.referer_user_id
    Notification.deliver_welcome(self)
  end
  
  def self.suspicious_users
    res = []
    User.db_query("select user_id, count(*) from comments where netiquette_violation  = 't' and created_on >= now() - '1 week'::interval group by (user_id) having count(*) > 1 order by count(*) desc").each do |dbu|
      u = User.find(dbu['user_id'].to_i)
      next if u.state == User::ST_BANNED
      res<< {:user => u, :suspiciousness => dbu['count'].to_i}
    end
    res
  end
  
  def self.random_with_photo(opts)
    opts = {:limit => 1, :exclude_user_id => nil, :exclude_friends_of_user_id => nil}.merge(opts)
    sql_user = opts[:exclude_user_id] ? "id <> #{opts[:exclude_user_id]} AND " : '' 
    User.find(:all, :conditions => "#{sql_user} photo is not null AND random_id > random() AND photo <> '' AND state NOT IN (#{User::STATES_CANNOT_LOGIN.join(',')})", :order => 'random_id', :limit => opts[:limit])
  end
  
  def self.random_same_city(user, opts)
    opts = {:limit => 1}.merge(opts)
    User.find(:all, :conditions => ["id <> #{user.id} AND lower(city) = lower(?) AND random_id > random() AND id not in (#{user.friends_ids_sql}) and state NOT IN (#{User::STATES_CANNOT_LOGIN.join(',')})", user.city], :order => 'random_id', :limit => opts[:limit])
  end
  
  def User.possible_friends_of(user, opts)
    opts = {:limit => 1}.merge(opts)
    recs = user.friends_recommendations.find(:all, :conditions => 'added_as_friend IS NULL', :order => 'friends_recommendations.id', :limit => opts[:limit], :include => :recommended_user)
    FriendsRecommendation.gen_more_recommendations(user) if recs.size == 0
    recs
  end
  
  VALID_SEXUAL_ORIENTATIONS = [:women, :men, :both, :none]
  MALE=0
  FEMALE=1
  SEXUAL_ORIENTATIONS_REL = { :women => "sex = #{FEMALE}", :men => "sex = #{FEMALE}", }
  def self.find_by_sexual_desire(orientation, limit='all')
    
  end
  
  # named_scope :ligoteo, lambda {{ :conditions => ['state IN () AND ']}}
  # buscar usuarios que esten interesados en
  def self.ligoteo(interested_in, sex_of_searcher, user_id, limit=50)
    sex_sql = case interested_in
      when 'men':
        "sex = #{User::MALE}"
      when 'women':
        "sex = #{User::FEMALE}"
      when 'men women':
        "sex IS NOT NULL"
    end
    
    sex_of_searcher_sql = case interested_in
      when User::MALE:
        "men"
      when User::FEMALE:
        "women"
    end
    
    # buscamos todos los usuarios interesados en #{interested_in}, que sean del sexo adecuado y que busquen pareja
    q = "SELECT a.id, a.login, a.avatar_id, a.photo
                        FROM users A 
                        JOIN users_preferences b ON a.id = b.user_id 
                        JOIN users_preferences c ON a.id = c.user_id
                       WHERE b.name = 'looking_for' 
                         AND (b.value LIKE '%amistad%' OR b.value LIKE '%pareja%' OR b.value LIKE '%quedar%')
                         AND c.name = 'interested_in'
                         AND c.value LIKE '%#{sex_of_searcher_sql}%' 
                         AND a.id <> #{user_id} 
                         AND #{sex_sql} GROUP BY a.id, a.login, a.avatar_id, a.photo
                       LIMIT #{limit}"
    User.find_by_sql(q)
  end
  
  def self.refered_users_in_time_period(t1, t2)
    t2, t1 = t1, t2 if t1 > t2
    User.db_query("SELECT count(*) 
                     FROM users 
                    WHERE referer_user_id is not null 
                      AND created_on BETWEEN '#{t1.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{t2.strftime('%Y-%m-%d %H:%M:%S')}'")[0]['count'].to_i
  end
end
