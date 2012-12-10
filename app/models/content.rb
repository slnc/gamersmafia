# -*- encoding : utf-8 -*-
class Content < ActiveRecord::Base

  CONTENT_TYPE_IDS = {
      "Bet" => 15,
      "Blogentry" => 17,
      "Column" => 12,
      "Coverage" =>  9,
      "Demo" => 23,
      "Download" =>  5,
      "Event" =>  8,
      "Funthing" => 14,
      "Image" =>  4,
      "Interview" => 11,
      "News" =>  1,
      "Poll" =>  7,
      "Question" => 24,
      "RecruitmentAd" => 25,
      "Review" => 13,
      "Topic" =>  6,
      "Tutorial" => 10,
  }

  after_create :do_after_create
  after_save :clear_save_locks
  after_save :create_decision_if_necessary
  after_save :do_after_save

  attr_accessor :cur_editor

  before_create :log_creation
  before_destroy :clear_comments
  before_destroy :change_to_deleted_state

  before_save :check_changed_attributes
  before_save :log_changes

  belongs_to :bazar_district
  belongs_to :clan
  belongs_to :content_type
  belongs_to :game
  belongs_to :gaming_platform
  belongs_to :portal
  belongs_to :user

  has_many :comments, :dependent => :destroy
  has_many :content_attributes
  has_many :content_ratings, :dependent => :destroy
  has_many :contents_locks, :dependent => :destroy
  has_many :contents_recommendations, :dependent => :destroy
  has_many :contents_terms, :dependent => :destroy
  has_many :contents_versions, :dependent => :destroy
  has_many :terms, :through => :contents_terms
  has_many :tracker_items, :dependent => :destroy
  has_many :users_contents_tags, :dependent => :destroy

  scope :draft, :conditions => "state = #{Cms::DRAFT}"
  scope :pending, :conditions => "state = #{Cms::PENDING}"
  scope :published, :conditions => "state = #{Cms::PUBLISHED}"
  scope :deleted, :conditions => "state = #{Cms::DELETED}"
  scope :onhold, :conditions => "state = #{Cms::ONHOLD}"

  scope :content_type_name, lambda { |name| {
            :conditions => ["type = ?", name]
        }
  }

  scope :content_type_names, lambda { |names| {
            :conditions => ["type IN (?)", names]
        }
  }

  scope :in_portal, lambda { |portal|
    if portal.id == -1
      {:conditions => "bazar_district_id IS NULL"}
    else
      taxonomy = "#{ActiveSupport::Inflector.pluralize(self.class.name)}Category"
      {
        :conditions => [
          "id IN (
              SELECT content_id
              FROM contents_terms
              WHERE term_id IN (?))",
          portal.terms_ids(taxonomy)] }
    end
  }

  scope :in_term, lambda { |term|
      raise ArgumentError, "in_term(nil) called" if term.nil?
      {:conditions => [
          "id IN (SELECT content_id FROM contents_terms WHERE term_id = ?)",
          term.id]}
  }

  scope :in_term_ids, lambda { |term_ids|
      {:conditions => [
          "id IN (SELECT content_id FROM contents_terms WHERE term_id IN (?))",
          term_ids]}
  }

  scope :in_term_tree, lambda { |term|
      {:conditions => [
          "id IN (SELECT content_id FROM contents_terms WHERE term_id IN (?))",
          term.all_children_ids]}
  }

  scope :most_popular,
    :conditions => "cache_rated_times > 1",
    :order => '(COALESCE(hits_anonymous, 0) +
                COALESCE(hits_registered * 2, 0) +
                COALESCE(cache_comments_count * 10, 0) +
                COALESCE(cache_rated_times * 20, 0)) DESC'

  scope :most_rated,
      :conditions => 'cache_rated_times > 1',
      :order => 'coalesce(cache_weighted_rank, 0) DESC'


  scope :of_interest_to, lambda {|user|
    # We need these 3 queries in order to find contents associated with
    # categories associated with the top level terms that the user has an
    # interest in.

    # Hack until we anonymous users have profiles oo.
    return {} if user.nil?

    game_ids = UserInterest.game_ids_of_interest(user)
    gaming_platform_ids = UserInterest.gaming_platform_ids_of_interest(user)
    bazar_district_ids = UserInterest.bazar_district_ids_of_interest(user)
    {:conditions => ["id IN (
                       SELECT content_id
                       FROM contents_terms
                       WHERE term_id IN (
                         SELECT entity_id
                         FROM user_interests
                         WHERE user_id = ?
                         AND entity_type_class = 'Term')
                      OR game_id IN (?)
                      OR gaming_platform_id IN (?)
                      OR bazar_district_id IN (?)
                      )",
                     user.id,
                     game_ids,
                     gaming_platform_ids,
                     bazar_district_ids]}
  }

  scope :recent, :conditions => "created_on >= now() - '3 months'::interval"

  scope :with_tags_from_user, lambda { |tags,user|
      {:conditions => [
          'contents.id IN (SELECT content_id
                             FROM users_contents_tags
                            WHERE user_id = ?
                              AND original_name IN (?))', user, tags]}
  }

  serialize :log

  validates_presence_of :user
  validates_presence_of :title

  def self.final_decision_made(decision)
    content = Content.find(decision.context.fetch(:content_id))
    if Cms::NO_MODERATION_NEEDED_CONTENTS.include?(content.type)
      raise (
          "Received decision for content of type '#{content.type}'
          for which no moderation is needed.")
    end

    expected_class = "Publish#{content.type}"
    if decision.decision_type_class != expected_class
      raise (
          "Mismatch between decision_type_class and content_type:
          #{decision.decision_type_class} != #{expected_class}")
    end

    self.handle_publish_decision(decision, content)
  end

  def self.most_popular_authors(opts)
    q_add = opts[:conditions] ? " AND #{opts[:conditions]}" : ''
    opts[:limit] ||= 5
    dbitems = User.db_query(
        "SELECT count(id),
           user_id
         FROM contents
         WHERE type = #{self.type}
         AND state = #{Cms::PUBLISHED}#{q_add}
         GROUP BY user_id
         ORDER BY SUM((coalesce(hits_anonymous, 0) +
                  COALESCE(hits_registered * 2, 0) +
                  COALESCE(cache_comments_count * 10, 0) +
                  COALESCE(cache_rated_times * 20, 0))) DESC
         LIMIT #{opts[:limit]}")
    dbitems.collect { |dbitem|
      [User.find(dbitem['user_id']), dbitem['count'].to_i]
    }
  end

  # devuelve los contenidos publicados mejor valorados
  def self.best_rated(opts={})
    opts = {:limit => 5}.merge(opts)
    q_add = opts[:conditions] ? " AND #{opts[:conditions]}" : ''

    self.published.find(
        :all,
        :conditions => "cache_rated_times > 1#{q_add}",
        :order => 'COALESCE(cache_weighted_rank, 0) DESC,
                   (hits_anonymous + hits_registered) DESC',
        :limit => opts[:limit])
  end

  # devuelve los contenidos publicados más populares (considera hits,
  # comentarios y veces valorado)
  def self.most_popular(opts={})
    opts[:limit] ||= 3

    self.published.find(
        :all,
        :conditions => opts[:conditions],
        :order => '(COALESCE(hits_anonymous, 0) +
                    COALESCE(hits_registered * 2, 0) +
                    COALESCE(cache_comments_count * 10, 0) +
                    COALESCE(cache_rated_times * 20, 0)) DESC',
        :limit => opts[:limit])
  end

  def self.handle_publish_decision(decision, content)
    if decision.final_decision_choice.name == Decision::BINARY_YES
      prev_state = content.state
      content.change_state(Cms::PUBLISHED, Ias.MrMan)
      if prev_state == Cms::PENDING
        self.create_alert_after_crowd_publishing_decision(content, "publicado")
      end
      decision.context[:result] = (
          "<a href=\"#{Routing.gmurl(content)}\">Ver contenido</a>")
      decision.save
    else
      prev_state = content.state
      content.change_state(Cms::DELETED, Ias.MrMan)
      if prev_state == Cms::PENDING
        self.create_alert_after_crowd_publishing_decision(content, "denegado")
      end
    end
  end

  def self.published_counts_by_user(user)
    out = {}
    User.db_query(
        "SELECT COUNT(*) AS cnt,
           type AS content_type_name
        FROM contents
        WHERE user_id = #{user.id}
        AND state = #{Cms::PUBLISHED}
        GROUP BY type").each do |row|
      out[row['content_type_name']] = row['cnt'].to_i
    end
    CONTENT_TYPE_IDS.keys.each do |k|
      out[k] ||= 0
    end
    out
  end

  def self.delete_content(real_item, user, reason="(sin razón)")
    self.modify_content_state(real_item, user, Cms::DELETED, reason)
  end

  def self.deny_content_directly(content, user, reason)
    self.modify_content_state(content, user, Cms::DELETED, reason)
  end

  def self.publish_content_directly(content, user)
    self.modify_content_state(content, user, Cms::PUBLISHED)
  end

  def self.recover_content(content, user)
    self.publish_content_directly(content, user)
  end

  def self.send_draft_to_moderation_queue(content)
    self.modify_content_state(content, content.user, Cms::PENDING)
  end

  def self.create_alert_after_crowd_publishing_decision(content, action_taken)
    ttype, scope = Alert.fill_ttype_and_scope_for_content_report(content)
    content_url = Routing.url_for_content_onlyurl(content)
    Alert.create({
      :type_id => ttype,
      :scope => scope,
      :reporter_user_id => Ias.MrMan.id,
      :headline => (
          "#{Cms.faction_favicon(content)}<strong>
          <a href=\"#{content_url}\">#{content.resolve_html_hid}</a>
          </strong> #{action_taken}"),
    })
  end

  # Call this function if you want to change a content state regardless outside
  # of the moderation queue voting mechanism.
  def self.modify_content_state(content, user, new_state, reason=nil)
    prev_state = content.state
    content.change_state(new_state, user)
    # TODO(slnc): update Decisions wrong on this content
  end

  def self.delete_duplicated_comments
    total= 0
    User.db_query("
        SELECT COUNT(*) as cnt,
          content_id,
          comment
        FROM comments
        WHERE updated_on >= now() - '2 days'::interval
        GROUP BY comment,
          content_id
        HAVING count(*) > 1
      ").each do |dbrow|
      content = Content.find(dbrow['content_id'].to_i)
      total += content.delete_duplicated_comments
    end
    total
  end

  def self.orphaned
    q_cts = Cms::CONTENTS_WITH_CATEGORIES.collect { |ctn| "'#{ctn}'"}
    Content.find_by_sql("
      SELECT *
      FROM contents
      WHERE content_type_id in (
        SELECT id
        FROM content_types
        WHERE name IN (#{q_cts.join(',')}))
      AND id not in (SELECT id FROM contents_terms)
      ORDER BY id
      LIMIT 10")
  end

  def to_s
    ("Content: id: #{self.id}, type: #{self.type}," +
     " name: #{self.title}")
  end

  # Procesa los campos wysiwyg y manipula las imágenes en caso de
  # encontrarlas: se las descarga si son remotas y crea thumbnails si están
  # resizeadas y no tienen ya un link alrededor.
  def process_wysiwyg_fields
    attrs = {}

    if !Cms::DONT_PARSE_IMAGES_OF_CONTENTS.include?(self.type) then
      for d in Cms::WYSIWYG_ATTRIBUTES[self.type]
        attrs[d] = Cms::parse_images(
            self.attributes[d],
            "#{self.type.downcase}/#{self.id % 1000}/#{self.id}")
      end
    end

    self.update_attributes(attrs)
  end

  def new_content_type_id
    CONTENT_TYPE_IDS.fetch(self.type)
  end

  # this content's contributed karma
  def karma
    self.karma_points
  end

  # arg[0] arg
  # arg[1] taxonomy
  def categories_terms_ids=(arg)
    self.categories_terms_ids=(arg)
    self.reload # necesario porque no se borra la cache del objeto de terms
  end

  def root_terms_add_ids(arg)
    self.root_terms_add_ids(arg)
    self.reload # necesario porque no se borra la cache del objeto de terms
  end

  def categories_terms
    self.categories_terms
  end

  def categories_terms_add_ids(arg, taxonomy)
    self.categories_terms_add_ids(arg, taxonomy)
    self.reload # necesario porque no se borra la cache del objeto de terms
  end

  def resolve_portal_id
    # primero los fáciles
  end

  def rating
    # devuelve el rating del contenido
    if (self.cache_rating.nil? && self.cache_rated_times.nil?) ||
      (self.cache_rating.nil? && self.cache_rated_times >= 2)
      self.recalculate_rating
    end

    if self.cache_rated_times < 2 then
      [nil, '<2']
    else
      [self.cache_rating, self.cache_rated_times]
    end
  end

  def recalculate_rating
    self.cache_rating = Content.db_query(
      "SELECT avg(rating) from content_ratings where content_id = #{self.id}")[0]['avg']
    self.cache_rated_times = Content.db_query(
      "SELECT count(id) from content_ratings where content_id = #{self.id}")[0]['count']
    self.cache_rating = 0 if self.cache_rating.nil?

    # imdb formula
    # r = average for the movie (mean) = (Rating)
    # v = number of votes for the movie = (votes)
    # m = minimum votes required to be listed in the Top 250 (currently 1250)
    # c = the mean vote across the whole report (currently 6.8)
    r = self.cache_rating.to_f
    v = self.cache_rated_times.to_f

    # cogemos el numero de votos como el valor del 1er cuartil ordenando la
    # lista de contenidos por votos asc
    # calculamos "m"
    if Cms::CONTENTS_WITH_CATEGORIES.include?(self.type) then
      return 0 if self.main_category.nil?# TODO hack temporal
      total = self.class.in_term(self.main_category.root).count
      # TODO esto debería ir en term
      joined_children = self.main_category.root.all_children_ids(
        :content_type => self.type).join(',')
        q = "SELECT content_id
             FROM contents
             JOIN contents_terms ON contents.id = contents_terms.content_id
            WHERE contents.state = #{Cms::PUBLISHED}
              AND term_id IN (#{joined_children})"

        contents_ids = User.db_query(q).collect { |dbr| dbr['content_id'] }
        q = "AND contents.id IN (#{contents_ids.join(',')})"
    else
      q = ''
      total = self.class.count(:conditions => "state = #{Cms::PUBLISHED} #{q}")
    end

    dbm = User.db_query(
      "SELECT cache_rated_times
     FROM contents
     WHERE state = #{Cms::PUBLISHED} #{q}
     AND type = '#{self.type}'
     AND cache_rated_times > 0
     ORDER BY cache_rated_times
     LIMIT 1 OFFSET #{(total/100*25 + 0.5).to_i}")

   if dbm.size > 0 then
     m = dbm[0]['cache_rated_times'].to_i
   else
     m = 2
   end

   c = get_mean_vote(m)
   self.cache_weighted_rank = (v / (v+m)) * r + (m / (v+m)) * c
   self.update_without_timestamping
  end

  def clear_rating_cache
    self.class.db_query("UPDATE contents
                              SET cache_rating = NULL,
                                  cache_rated_times = NULL,
                                  cache_weighted_rank = NULL WHERE id = #{self.id}")
                                  self.cache_rating = nil
                                  self.cache_rated_times = nil
                                  self.cache_weighted_rank = nil
                                  self.rating # TODO PERF
  end

  def hit_anon
    self.class.increment_counter('hits_anonymous', self.id)
  end

  def hit_reg(user)
    self.class.increment_counter('hits_registered', self.id)

    # si el usuario no tiene un elemento del tracker para este contenido lo creamos
    tracker_item = TrackerItem.find(
        :first,
        :conditions => ['user_id = ? and content_id = ?',
                        user.id, self.id])

    if not tracker_item then
      tracker_item = TrackerItem.new(
          :user_id => user.id, :content_id => self.id)
    end

    tracker_item.lastseen_on = Time.now

    begin
      tracker_item.save
      cr = ContentsRecommendation.find(:first, :conditions => ['receiver_user_id = ? AND content_id = ? AND seen_on IS NULL', user.id, self.id])
      cr.mark_seen if cr
    rescue ActiveRecord::StatementInvalid
      # try again, maybe overloaded
      TrackerItem.find(:first, :conditions => ['user_id = ? and content_id = ?', user.id, self.id])
    end
  end

  def is_locked_for_user?(user)
    self.locked_for_user?(user)
  end

  def lock(user)
    self.lock(user)
  end

  def cur_lock
    self.cur_lock
  end

  def is_public?
    self.state == Cms::PUBLISHED
  end

  def get_mean_vote(m)
    # calcula el voto medio para un contenido dependiendo de si tiene categoría o no
    # asumo que cada contenido y cada facción tiene su propia media
    if Cms::CONTENTS_WITH_CATEGORIES.include?(self.type) then
      return 0 if self.main_category.nil?# TODO hack temporal
      # cat_ids = self.main_category.root.all_children_ids
      # TODO esto deberia ir en Term

      joined_children = self.main_category.root.all_children_ids(
          :content_type => self.type).join(',')
      contents_ids = User.db_query(
        "SELECT content_id
         FROM contents
         JOIN contents_terms ON contents.id = contents_terms.content_id
         WHERE contents.state = #{Cms::PUBLISHED}
         AND term_id IN (#{joined_children})").collect {|dbr| dbr['content_id']}

      mean = User.db_query("SELECT avg(cache_rating)
                              FROM contents
                             WHERE cache_rating is not null
                               AND type = '#{self.type}'
                               AND cache_rated_times >= #{m}
                               AND id IN (#{contents_ids.join(',')})")[0]['avg'].to_f
    else
      mean = User.db_query("SELECT avg(cache_rating)
                              FROM contents
                             WHERE cache_rating is not null
                               AND type = '#{self.type}
                               AND cache_rated_times >= #{m}")[0]['avg'].to_f
    end
  end

  def recover(user)
    self.state = Cms::PUBLISHED
    self.log_action('recuperado', user)
    self.save
  end

  # funciones para crear contenido único
  def change_state(new_state, editor)
    return if new_state == self.state || self.invalid?

    case new_state
    when Cms::DRAFT
      raise 'impossible'

    when Cms::PENDING
      raise 'impossible' unless self.state == Cms::DRAFT
      self.log_action('enviado a cola de moderación', editor)

    when Cms::PUBLISHED
      if ![Cms::PENDING, Cms::DELETED, Cms::ONHOLD, Cms::DRAFT].include?(self.state)
        raise "impossible, current_state #{self.id} = #{self.state}"
      end
      # solo le cambiamos la hora si el estado anterior era cola de moderación
      self.created_on = Time.now if self.state == Cms::PENDING
      self.log_action('publicado', editor)
      self.tracker_items.each do |ti|
        ti.lastseen_on = Time.now
        ti.save
      end

      # Update tracker_items so they don't figure as updated
    when Cms::DELETED
      raise 'impossible' unless [Cms::PENDING, Cms::PUBLISHED, Cms::ONHOLD, Cms::DRAFT].include?(self.state)
      self.log_action('borrado', editor)
      ContentsRecommendation.find(
        :all,
        :conditions => ['content_id = ?',
          self.id]).each do |cr|
        cr.destroy
          end

    when Cms::ONHOLD
      raise 'impossible' unless [Cms::PUBLISHED, Cms::DELETED, Cms::ONHOLD].include?(self.state)
      self.log_action('movido a espera', editor)

    else

      raise 'unimplemented'
    end
    self.state = new_state
    self.save # TODO y si falla qué debería hacer change_state?
  end

  def top_tags
    self.terms.contents_tags.find(:all, :order => 'lower(name)')
  end

  def change_to_deleted_state
    self.update_attribute(:state, Cms::DELETED)
    self.terms.each do |term|
      term.resolve_last_updated_item
    end
    true
  end

  def ne_references
    NeReference.find(:all,
                     :conditions => ['(referencer_class = \'Content\' AND referencer_id = ?) OR (referencer_class = \'Comment\' AND referencer_id IN (?))', self.id, comment_ids])
  end

  def comments_ids
    self.db_query("SELECT id FROM comments WHERE content_id = #{self.id} AND deleted = 'f'").collect { |dbr| dbr['id'].to_is }
  end

  def check_changed_attributes
    g_id = self.get_game_id
    if g_id != self.game_id
      self.game_id = g_id
    else
      p_id = self.get_my_gaming_platform_id
      if p_id
        self.gaming_platform_id = p_id
      else # maybe bazar_district
        bd_id = self.get_my_bazar_district_id
        self.bazar_district_id = bd_id if bd_id
      end
    end

    if self.state_changed? && self.state != Cms::PUBLISHED
      self.contents_recommendations.each { |cr| cr.destroy }
    end

    true
  end

  def my_faction
    Faction.find(
      :first,
      :conditions => "code = (SELECT slug FROM games WHERE id = #{game_id})")
  end

  def my_bazar_district
    BazarDistrict.find(:first, :conditions => ["slug = ?", self.portal.code])
  end

  def clear_comments
    self.comments.clear
  end

  def locked_for_user?(user)
    mlock = cur_lock
    (mlock && mlock.user_id != user.id)
  end

  def cur_lock
    self.contents_locks.active.last
  end

  def lock(user)
    mlock = cur_lock
    if mlock && mlock.user_id != user.id
      raise AccessDenied
    elsif mlock
      mlock.save # touch updated_on
    else
     # borramos si queda alguno viejo
      self.contents_locks.delete_all
      cl = ContentsLock.create(:content_id => self.id, :user_id => user.id)
      if cl.new_record?
        raise "Cannot create lock: #{cl.errors.full_messages_html}"
      end
      cl
    end
  end

  def linked_terms(taxonomy)
    self.terms.with_taxonomy(taxonomy).find(:all, :order => 'created_on')
  end

  def root_terms
    if self.game_id
      taxonomy = "Game"
    elsif self.gaming_platform_id
      taxonomy = "GamingPlatform"
    elsif self.clan_id
      taxonomy = "Clan"
    elsif self.bazar_district_id
      taxonomy = "BazarDistrict"
    else
      # gm
      taxonomy = "Homepage"
    end
    # TODO(slnc): temp hack until we git read of dual content classes
    root_terms = self.linked_terms(taxonomy)
    if root_terms.size == 0
      self.terms.with_taxonomies(%w(Game GamingPlatform Clan BazarDistrict Homepage)).find(:all)
    else
      root_terms
    end
  end

  def categories_terms(taxonomy)
    self.linked_terms(taxonomy)
  end

  # Devuelve la primera categoría asociada a este contenido
  def main_category
    # DEPRECATED
    if Cms::ROOT_TERMS_CONTENTS.include?(self.type)
      cats = self.root_terms
    else
      cats = self.linked_terms("#{ActiveSupport::Inflector::pluralize(self.type)}Category")
    end

    if cats.size > 0
      cats[0]
    else
      self.root_terms[0]
    end
  end

  def get_game_id
    if Cms::CONTENTS_WITH_CATEGORIES.include?(self.type) then
      maincat = self.main_category
      return unless maincat
      tld_code = maincat.root.code
      g = Game.find_by_slug(tld_code)
      g.id if g
    end
  end

  def get_my_gaming_platform_id
    if Cms::CONTENTS_WITH_CATEGORIES.include?(self.type) then
      maincat = self.main_category
      return unless maincat
      tld_code = maincat.root.code
      p = GamingPlatform.find_by_slug(tld_code)
      p.id if p
    end
  end

  def get_my_bazar_district_id
    if Cms::CONTENTS_WITH_CATEGORIES.include?(self.type) then
      maincat = self.main_category
      return unless maincat
      tld_code = maincat.root.code
      p = BazarDistrict.find_by_slug(tld_code)
      p.id if p
    end
  end

  def my_faction
    if self.main_category.nil?
      Rails.logger.warn("No main_category found for #{self}")
      raise ActiveRecord::RecordNotFound
    end
    Faction.find_by_name(self.main_category.root.name)
  end

  def resolve_hid
    if self.title.to_s != ""
      self.title
    elsif self.type == "Image" && self.file.to_s != ""
      File.basename(im.varchar_value)
    else
      self.id.to_s
    end
  end

  def resolve_html_hid
    if self.title.to_s != ""
      self.title
    elsif self.type == "Image" && self.file.to_s != ""
      "<img src=\"/cache/thumbnails/f/85x60/#{im.varchar_value}\" />"
    else
      self.id.to_s
    end
  end

  #def terms=(new_terms)
  #  @_terms_to_add ||= []
  #  new_terms = [new_terms] unless new_terms.kind_of?(Array)
  #  @_terms_to_add += new_terms
  #end

  # Devuelve los portales en los que este contenido se muestra.
  # TODO esto no es correcto
  def get_related_portals
    if self.respond_to?(:clan_id) && self.clan_id && self.type != 'RecruitmentAd'
      [ClansPortal.find_by_clan_id(self.clan_id)]
    else
      portals = [GmPortal.new, ArenaPortal.new, BazarPortal.new]
      f = Organizations.find_by_content(self)
      if f.nil? then # No es un contenido de facción o es de categoría gm/otros TODO esto no usarlo con caches, madre del amor hermoso
        portals += Portal.find(:all, :conditions => 'type <> \'ClansPortal\'')
      elsif f.class.name == 'Faction'
        # TODO plataforma PC va a fallar
        portals += Portal.find(:all, :conditions => ['id in (SELECT portal_id from factions_portals where faction_id = ?)', f.id])
      elsif f.class.name == 'BazarDistrict'
        portals += [Portal.find_by_code(f.code)]
      end
      portals
    end
  end

  def main_image
    candidates = []

    [:description, :main].each do |field|
      if self.respond_to?(field)
        images = Cms.extract_html_images(self.send(field))
        if images.size > 0
          image = images[0].gsub("http://", "")
          domain = image.split("/")[0]
          return image.sub(domain, "")
        end
      end
    end
    nil
  end


  def root_terms_ids=(newt)
    newt = [newt] unless newt.kind_of?(Array)
    existing = self.root_terms.collect { |t| t.id }
    to_del = existing - newt
    to_add = newt - existing
    root_terms_add_ids(to_add)
    to_del.each { |tid| self.contents_terms.find(:first, :conditions => ['term_id = ?', tid]).destroy }
    # We force an update of the url
    self.url = nil
    Routing.url_for_content_onlyurl(self)
    self.save
    true
  end

  def categories_terms_ids=(arg)
    newt = arg[0]
    taxonomy = arg[1]
    newt = [newt] unless newt.kind_of?(Array)
    existing = self.categories_terms(taxonomy).collect { |t| t.id }
    to_del = existing - newt
    to_add = newt - existing
    categories_terms_add_ids(to_add, taxonomy)
    to_del.each { |tid| self.contents_terms.find(:first, :conditions => ['term_id = ?', tid]).destroy }
    # We force an update of the url
    self.url = nil
    Routing.url_for_content_onlyurl(self)
    self.save
    true
  end

  def root_terms_add_ids(terms)
    terms = [terms] unless terms.kind_of?(Array)
    terms.each do |tid|
      t = Term.find(:first, :conditions => ["id = ? AND parent_id IS NULL", tid])
      t.link(self)
    end
    self.url = nil
    Routing.url_for_content_onlyurl(self)
    self.save
    true
  end

  def categories_terms_add_ids(terms, taxonomy)
    terms = [terms] unless terms.kind_of?(Array)
    terms.each do |tid|
      t = Term.find_taxonomy(tid, taxonomy)
      t.link(self)
    end
    self.url = nil
    Routing.url_for_content_onlyurl(self)
    self.save
    true
  end

  def delete_duplicated_comments
    previous = nil
    i = 0
    self.comments.find(:all, :order => 'id').each do |comment|
      if (previous &&
          previous.comment == comment.comment &&
          previous.user_id == comment.user_id)
        i += 1
        comment.update_attributes(:state => Comment::DUPLICATED)
      end
      previous = comment
    end
    i
  end

  def create_decision_if_necessary
    if (self.state_changed? && self.state == Cms::PENDING &&
        (self.state_was == Cms::DRAFT || self.state_was.nil?))
      self.delay.schedule_publish_content_decision
    end
  end

  def schedule_publish_content_decision
    if Cms::NO_MODERATION_NEEDED_CONTENTS.include?(self.type)
      return
    end
    if self.type == "Image"
      content_name = (
          "<img src=\"/cache/thumbnails/i/85x60/#{self.file}\" />")
    else
      content_name = self.title
    end

    Decision.create({
      :decision_type_class => "Publish#{self.type}",
      :context => {
        :content_id => self.id,
        :content_name => self.title,
        :initiating_user_id => self.user_id,
      },
    })
  end

  def log_action(action_name, author=nil, reason=nil)
    self.log ||= []
    if !(self.log.size > 0 &&
         self.log[-1][0] == action_name &&
         self.log[-1][2] > 5.seconds.ago)  # dupcheck
      self.log<< [action_name, author.to_s, Time.now, reason]
    end
  end

  def comments_ids
    User.db_query("SELECT id FROM comments WHERE content_id = #{self.id}").collect! { |dbc| dbc['id']}
  end

  def last_comment
    self.comments.karma_eligible.last
  end

  def has_category?
    Cms::CONTENTS_WITH_CATEGORIES.include?(self.type)
  end

  def change_authorship(new_user, editor)
    raise ValueError if !new_user.kind_of?(User)
    return if new_user.id == self.user_id

    # TODO ya no :p hacemos esto para no triggerear record_timestamps
    # self.class.db_query("UPDATE #{ActiveSupport::Inflector::tableize(self.class.name)} SET user_id = #{new_user.id} WHERE id = #{self.id}")
    # self.reload
    self.user_id = new_user.id
    self.user = new_user # necesario hacer ambos cambios por si ya se ha cargado self.user antes
    self.log_action('cambiada autoría', editor)
    self.save
  end

  def closed_by_user
    return nil unless self.closed?
    self.log.reverse.each do |lentry|
      if lentry[0] == 'cerrado'
        return User.find_by_login(lentry[1])
      end
    end
  end

  def reason_to_close
    return nil unless self.closed?
    self.log.reverse.each do |lentry|
      if lentry[0] == 'cerrado'
        return lentry[3]
      end
    end
  end

  def close(user, reason)
    return if self.closed?
    self.closed = true
    self.log_action('cerrado', user, reason)
    self.save
  end

  def reopen(user)
    return unless self.closed?
    self.closed = false
    self.log_action('reabierto', user)
    self.save
  end


  private
  def clear_save_locks
    self.contents_locks.clear if self.contents_locks
    old_url = self.url
    new_url = Routing.gmurl(self)
    if old_url != new_url  # url has changed, let's update comments
      User.db_query(
          "UPDATE comments
              SET portal_id = #{self.portal_id}
            WHERE content_id = #{self.id}")
    end
  end

  def do_after_create
    Users.add_to_tracker(self.user, self)
  end

  def do_after_save
    return false if self.id.nil?

    if @_terms_to_add
      @_terms_to_add.each do |tid|
        Term.find(tid).link(self)
      end
      @_terms_to_add = []
      if self.id
        self.url = nil
        Routing.gmurl(self)
      end
    end

    true
  end

  def do_before_save
    if self.source
      if self.source.strip == ''
        self.source = nil
      else
        if !(Cms::URL_REGEXP =~ self.source)
          self.errors.add('source', 'URL incorrecta')
          return false
        end
      end
    end

    attrs = {}
    # TODO llamar específicamente a esta función para actualizar las imágenes
    if !Cms::DONT_PARSE_IMAGES_OF_CONTENTS.include?(self.type) && self.record_timestamps
      tmpid = id
      tmpid = 0 if self.id.nil?
      Cms::WYSIWYG_ATTRIBUTES[self.type].each do |d|
        attrs[d] = Cms::parse_images(
            self.attributes[d], "#{self.type.downcase}/#{tmpid % 1000}")
      end

      self.attributes = attrs
    end

    # TODO más inteligencia?
    # creamos versión si se ha cambiado title, description, main o el campo de
    # categoría
    # self.class.find(self.id)
    if !self.new_record? && self.id
      oldv = self.class.find(self.id).attributes
      copy = false
      %w(title description main).each do |attr|
        if self.respond_to?(attr) && oldv[attr] != self.send(attr)
          copy = true
          break
        end
      end

      self.contents_versions.create(:data => oldv) if copy
    end

    if self.respond_to?(:title)
      if self.title.to_s.strip == ''
        self.errors.add('title', 'El título no puede estar en blanco')
        return false
      else
        if self.title.upcase == self.title && self.title.size > 10
          self.title = self.title.downcase.titleize
        end
        if self.title[-1..-1] == '.'
          self.title = self.title[0..-2]
        end
        true
      end
    end

    true
  end

  def log_creation
    self.log = nil
    self.log_action('creado', self.user.login)
  end

  def log_changes
    if !self.log_changed?
      if self.cur_editor
        if self.cur_editor.kind_of?(Fixnum)
          self.cur_editor = User.find(self.cur_editor)
        end
        self.log_action('modificado', self.cur_editor)
      end
    end

    if self.attributes[:terms]
      if !self.attributes[:terms].kind_of(Array)
        self.attributes[:terms] = [self.attributes[:terms]]
      end
      @_terms_to_add = self.attributes[:terms]
      self.attributes.delete :terms
    end
    true
  end
end
