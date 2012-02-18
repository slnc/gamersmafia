class SlogEntry < ActiveRecord::Base
  TYPES = {
    :info => 0,
    :security => 1,
    :error => 2,
    :multiple_accounts => 3,
    :user_report => 4,
    :general_content_report => 5,
    :general_comment_report => 6,
    :clan_report => 7,
    :emergency_antiflood => 8,
    :faction_content_report => 9,
    :bazar_district_content_report => 10,
    :faction_comment_report => 11,
    :bazar_district_comment_report => 12,
    :faction_topic_report => 13,
    :new_avatar => 14,
  }

  # TODO dejar de usar :info

  DOMAINS_TYPES = { :bazar_manager => [],
    :bazar_district_bigboss => [],
    :capo => [:info, :security, :multiple_accounts, :user_report, :general_content_report, :general_comment_report, :clan_report, :emergency_antiflood, :new_avatar],
    :competition_admin => [],
    :competition_supervisor => [],
    :editor => [:faction_content_report],
    :faction_bigboss => [],
    :gladiador => [],
    :moderator => [:faction_topic_report, :faction_comment_report],
    :sicario => [:bazar_district_content_report, :bazar_district_comment_report],
    :webmaster => [:error]
  }

  VALID_ROLES = %w(Don ManoDerecha Sicario Moderator Editor Boss Underboss CompetitionAdmin CompetitionSupervisor)

  USERS_ROLES_2_DOMAINS = {
  'Don' => :bazar_district_bigboss,
  'ManoDerecha' => :bazar_district_bigboss,
  'Sicario' => :sicario,
  'Moderator' => :moderator,
  'Editor' => :editor,
  'Boss' => :faction_bigboss,
  'Underboss' => :faction_bigboss,
  'CompetitionAdmin' => :competition_admin,
  'CompetitionSupervisor' => :competition_supervisor
  }

  # VALID_DOMAINS = DOMAINS_TYPES.keys

  EDITOR_SCOPE_CONTENT_TYPE_ID_MASK = 1000

  DOMAINS_NEEDING_SCOPE = [:faction_bigboss, :bazar_district_bigboss, :competition_admin, :competition_supervisor, :editor, :moderator, :sicario]

  OLD_SLOG_EXCLUDE = [TYPES[:info], TYPES[:error]]

  validates_presence_of :type_id
  validates_length_of :headline, :within => 1..8000
  plain_text :info
  belongs_to :reviewer, :class_name => 'User', :foreign_key => 'reviewer_user_id'
  belongs_to :reporter, :class_name => 'User', :foreign_key => 'reporter_user_id'

  before_save :check_reporter_user_id
  before_save :check_scope

  before_create :populate_reporter

  after_save :update_pending_slog

  CLOSED_SQL = 'completed_on IS NOT NULL'
  OPEN_SQL = 'completed_on IS NULL AND reviewer_user_id IS NULL'

  scope :closed, :conditions => CLOSED_SQL
  scope :open, :conditions => OPEN_SQL
  scope :assigned_to_me,
        lambda { |user_id|
            {:conditions => ["completed_on IS NULL AND reviewer_user_id = ?",
                             user_id]}
        }
  scope :assigned_to_others,
        lambda { |user_id|
            {:conditions => ["completed_on IS NULL AND reviewer_user_id IS" +
                             " NOT NULL AND reviewer_user_id <> ?", user_id]
            }
        }
  scope :in_domain_and_scope, lambda { |domain, scope|
    valid_types = self.valid_types_from_domain(domain)
    scope_conditions = self._process_scope(:domain => domain, :scope => scope)
    { :conditions => "#{sql_cond} AND type_id IN (#{valid_types.join(',')})" }
  }

  def update_pending_slog
    # TODO hacer en segundo plano
    # buscamos usuarios que puedan hacerse cargo de esta entrada de slog y actualizamos el num de entradas pendientes

    users = case SlogEntry.domain_from_type_id(self.type_id)
      when :faction_bigboss
      f = Faction.find(scope)
      [f.boss, f.underboss]

      when :bazar_district_bigboss
      f = BazarDistrict.find(scope)
      [f.don, f.mano_derecha]

      when :competition_admin
      c = Competition.find(scope).admins

      when :competition_supervisor
      Competition.find(scope).supervisors

    when :editor
      faction_id, content_type_id = SlogEntry.decode_editor_scope(scope)
      Faction.find(faction_id).editors(ContentType.find_by_id(content_type_id))

      when :moderator
      Faction.find(scope).moderators

      when :sicario
      BazarDistrict.find(scope).sicarios

      when :capo
      User.find_with_admin_permissions(:capo)

      when :bazar_manager
      User.find_with_admin_permissions(:bazar_manager)

      when :gladiador
      User.find_with_admin_permissions(:gladiador)

      when :webmaster
      [User.find(1)]
    else
      raise "update_pending_slog doesnt understand type_id #{self.type_id}"
    end

    users.each do |u|
      # Lo hacemos en diferido para evitar deadlocks que se están produciendo
      GmSys.job("SlogEntry.update_pending_slog(User.find_by_id(#{u.id}))")
    end
  end



  def self.update_pending_slog(u)
    # actualiza el campon pending_slog de u en base a sus permisos
    # TODO capo y bazar_manager falta
    total = 0

    total += ccount(:open, :domain => :capo) if u.has_admin_permission?(:capo)
    total += ccount(:open, :domain => :bazar_manager) if u.has_admin_permission?(:bazar_manager)
    total += ccount(:open, :domain => :gladiador) if u.has_admin_permission?(:gladiador)
    total += ccount(:open, :domain => :webmaster) if u.id == 1

    valid_roles = USERS_ROLES_2_DOMAINS.keys.collect { |k| "'#{k}'" }

    u.users_roles.find(:all, :conditions => "role IN (#{valid_roles.join(',')})").each do |ur|
      if ur.role == 'Editor'
        total += ccount(:open, :domain => :editor, :scope => SlogEntry.encode_editor_scope(ur.role_data_yaml[:faction_id].to_i, ur.role_data_yaml[:content_type_id].to_i))
      elsif ur.role_data.to_s != ''
        total += ccount(:open, :domain => USERS_ROLES_2_DOMAINS.fetch(ur.role), :scope => ur.role_data.to_i)
      else
        total += ccount(:open, :domain => USERS_ROLES_2_DOMAINS.fetch(ur.role))
      end
    end
    u.update_attributes(:pending_slog => total)
  end

  def populate_reporter
    self.reporter_user_id = User.find_by_login('MrAchmed').id if self.reporter_user_id.nil?
  end

  def check_scope
   (!DOMAINS_NEEDING_SCOPE.include?(self.type_id)) || (!self.scope.nil? && check_valid_scope)
  end

  def self.domain_from_type_id(type_id)
    domain = nil
    DOMAINS_TYPES.each do |k,v|
      if v.collect {|rr| TYPES[rr]}.include?(type_id)
        domain = k
        break
      end
    end
    domain
  end

  def check_valid_scope
    case SlogEntry.domain_from_type_id(self.type_id)
      when :faction_bigboss
      !Faction.find_by_id(scope).nil?
      when :bazar_district_bigboss
      !BazarDistrict.find_by_id(scope).nil?
      when :competition_admin
      !Competition.find_by_id(scope).nil?
      when :competition_supervisor
      !Competition.find_by_id(scope).nil?
      when :editor
      faction_id, content_type_id = SlogEntry.decode_editor_scope(scope)
      !Faction.find_by_id(faction_id).nil? && !ContentType.find_by_id(content_type_id).nil?
      when :moderator
      !Faction.find_by_id(scope).nil?
      when :sicario
      !BazarDistrict.find_by_id(scope).nil?
    else
      raise "checking scope of unscoped domain"
    end
  end

  def check_reporter_user_id
    self.reporter_user_id = User.find_by_login('MrAchmed') if self.reporter_user_id.nil?
  end

  def mark_as_resolved(resolver_user_id)
    raise AccessDenied unless self.completed_on.nil?
    self.reviewer_user_id = resolver_user_id if self.reviewer_user_id.nil?
    self.completed_on = Time.now
    self.save
  end

  VALID_GET_MODES = [:open, :assigned_to_me, :assigned_to_others, :closed]
  def self.get(mode, opts)
    sql_cond, valid_types = _process_get_query(mode, opts)
    opts2 = opts.clone
    opts2.delete(:scope)
    opts2.delete(:domain)
    opts2.delete(:user_id)
    SlogEntry.find(:all, {:conditions => "#{sql_cond} AND type_id IN (#{valid_types.join(',')})"}.merge(opts2))
  end

  def self.ccount(mode, opts)
    sql_cond, valid_types = _process_get_query(mode, opts)
    SlogEntry.count(:conditions => "#{sql_cond} AND type_id IN (#{valid_types.join(',')})")
  end

  def self.recursive_ccount(mode, opts)
    # devuelve total de incidencias del modo dado para el dominio y scope indicado incluyendo hijos
    total = ccount(mode, opts)
    # busco los domains y scopes hijos directos
    case opts[:domain]
      when :capo
      Faction.find(:all).each do |f|
        new_opts = opts.merge({:domain => :faction_bigboss, :scope => f.id})
        total += recursive_ccount(mode, opts.merge(new_opts))
      end
      when :bazar_manager
      BazarDistrict.find(:all).each do |bd|
        new_opts = opts.merge({:domain => :bazar_district_bigboss, :scope => bd.id})
        total += recursive_ccount(mode, opts.merge(new_opts))
      end
      when :faction_bigboss
      new_opts = opts.merge({:domain => :moderator})
      total += recursive_ccount(mode, opts.merge(new_opts))

      new_opts = opts.merge({:domain => :editor, :scope => encode_editor_scope(opts[:scope], nil)})
      total += recursive_ccount(mode, opts.merge(new_opts))

      when :district_bigboss
      new_opts = opts.merge({:domain => :sicario})
      total += recursive_ccount(mode, opts.merge(new_opts))
    end

    # types, scopes = get_child_types_and_scopes(mode, opts)
    # (modes + [mode]).each do |m|
    #   total += ccount(mode, opts)
    # end
    total
  end

  def self._process_get_query(mode, opts)
    raise "invalid mode" unless VALID_GET_MODES.include?(mode)
    raise "user_id not specified" if [:assigned_to_me, :assigned_to_others].include?(mode) && opts[:user_id].nil?
    opts = {:limit => 'all', :order => 'id DESC'}.merge(opts)

    sql_cond = case mode
      when :open
        OPEN_SQL
      when :assigned_to_me:
        "completed_on IS NULL AND reviewer_user_id = #{opts[:user_id]}"

      when :assigned_to_others:
        "completed_on IS NULL AND reviewer_user_id IS NOT NULL AND reviewer_user_id <> #{opts[:user_id]}"
      when :closed:
        CLOSED_SQL
    end

    sql_cond << self._process_scope(opts)
    [sql_cond, self.valid_types_from_domain(opts[:domain])]
  end

  def self._process_scope(opts)
    raise "domain not specified" unless opts[:domain]
    if DOMAINS_NEEDING_SCOPE.include?(opts[:domain]) && opts[:scope] == ''
      raise "scope not specified for #{opts[:domain]}"
    end

    if opts[:scope] && opts[:domain] == :editor
      if opts[:scope] % EDITOR_SCOPE_CONTENT_TYPE_ID_MASK == 0
        max_scope = (opts[:scope] + (EDITOR_SCOPE_CONTENT_TYPE_ID_MASK - 1))
        " AND scope BETWEEN #{opts[:scope]} AND #{max_scope} "
      else
        " AND scope = #{opts[:scope]} "
      end
    elsif opts[:scope] && DOMAINS_NEEDING_SCOPE.include?(opts[:domain])
      " AND scope = #{opts[:scope]} "
    else
      ""
    end
  end

  def self.valid_types_from_domain(domain)
    valid_types = DOMAINS_TYPES[domain].collect { |r| TYPES[r] }
    valid_types << [-1] if valid_types.size == 0
    valid_types
  end


  # para editores los 3 ultimos digitos del scope representan el content_type_id y los digitos por encima el faction_id
  def self.decode_editor_scope(scope)
    # returns faction_id, content_type_id
    [(scope / EDITOR_SCOPE_CONTENT_TYPE_ID_MASK).floor, (scope % EDITOR_SCOPE_CONTENT_TYPE_ID_MASK)]
  end

  def self.encode_editor_scope(faction_id, content_type_id)
    if content_type_id.nil? then # para poder especificar todos los content_type_id de golpe
      EDITOR_SCOPE_CONTENT_TYPE_ID_MASK * faction_id
    else
      EDITOR_SCOPE_CONTENT_TYPE_ID_MASK * faction_id + content_type_id
    end
  end

  def self.scopes(domain, u)
    case domain
      when :bazar_district_bigboss:
      if u.has_admin_permission?(:bazar_manager)
        BazarDistrict.find(:all, :order => 'lower(name)')
      else
        [BazarDistrict.find_by_bigboss(u)].compact
      end

      when :faction_bigboss:
      if u.has_admin_permission?(:capo)
        Faction.find(:all, :order => 'lower(name)')
      else
        [Faction.find_by_bigboss(u)].compact
      end

      when :moderator:
      if u.has_admin_permission?(:capo)
        Faction.find(:all, :order => 'lower(name)')
      else
        # en las que tenga moderator
        # en las que sea boss/under
        [Faction.find_by_bigboss(u)].compact + Faction.find_by_moderator(u)
      end

      when :editor:
      if u.has_admin_permission?(:capo)
        Faction.find(:all, :order => 'lower(name)').collect { |f| EditorScope.new(f.id, nil) }
      else
        # todas en las que sea boss
        fs = []
        f = Faction.find_by_bigboss(u)
        fs << EditorScope.new(f.id, nil) if f
        # mas todas las que tenga editor
        UsersRole.find(:all, :conditions => ['user_id = ? AND role = \'Editor\'', u.id]).collect do |ur|
          fs << EditorScope.new(ur.role_data_yaml[:faction_id], ur.role_data_yaml[:content_type_id])
        end
        fs
      end

      when :sicario:
      if u.has_admin_permission?(:bazar_manager)
        BazarDistrict.find(:all, :order => 'lower(name)')
      else
        [BazarDistrict.find_by_bigboss(u)].compact + BazarDistrict.find_by_sicario(u)
      end

      when :competition_admin:
      if u.has_admin_permission?(:gladiador)
        Competition.find(:all, :conditions => 'deleted = \'f\'', :order => 'lower(name)')
      else
        Competition.find_by_admin(u)
      end

      when :competition_supervisor:
      if u.has_admin_permission?(:gladiador)
        Competition.find(:all, :conditions => 'deleted = \'f\'', :order => 'lower(name)')
      else
        Competition.find_by_admin(u) + Competition.find_by_supervisor(u)
      end
    else
      raise "unknown domain #{domain}"
    end
  end

  def self.fill_ttype_and_scope_for_content_report(content)
    org = Organizations.find_by_content(content)
    if org
      if org.class.name == 'Faction' && content.content_type.name == 'Topic'
        ttype = :faction_topic_report
        scope = org.id
      elsif org.class.name == 'Faction'
        ttype =  :faction_content_report
        scope = org.id * SlogEntry::EDITOR_SCOPE_CONTENT_TYPE_ID_MASK + content.content_type_id
      else
        ttype = :bazar_district_content_report
        scope = org.id
      end
    else
      ttype = :general_content_report
      scope = nil
    end
    [TYPES.fetch(ttype), scope]
  end

  def self.reset_users_pending_slog
    us = User.find_with_admin_permissions(:capo)

    UsersRole.find(:all, :include => :user).each do |ur|
      us << ur.user
    end

    us.uniq!

    us.each { |u| SlogEntry.update_pending_slog(u) }
  end
end

class EditorScope
  def initialize(faction_id, content_type_id)
    @faction_id = faction_id
    @content_type_id = content_type_id
  end

  def id
    SlogEntry.encode_editor_scope(@faction_id.to_i, @content_type_id.to_i)
  end

  def name
    if @content_type_id
    "#{ContentType.find(@content_type_id).name} en #{Faction.find(@faction_id).name}"
    else
    "Todos en #{Faction.find(@faction_id).name}"
    end
  end
end
