# -*- encoding : utf-8 -*-
class Content < ActiveRecord::Base
  after_save :create_decision_if_necessary
  belongs_to :content_type
  before_destroy :clear_comments
  before_destroy :unlink_real_content
  has_many :comments, :dependent => :destroy
  has_many :contents_versions, :dependent => :destroy
  has_many :content_ratings, :dependent => :destroy
  has_many :tracker_items, :dependent => :destroy
  has_many :contents_locks, :dependent => :destroy
  has_many :contents_recommendations, :dependent => :destroy
  has_many :terms, :through => :contents_terms
  has_many :contents_terms, :dependent => :destroy
  has_many :users_contents_tags, :dependent => :destroy
  belongs_to :portal

  scope :draft, :conditions => "state = #{Cms::DRAFT}"
  scope :pending, :conditions => "state = #{Cms::PENDING}"
  scope :published, :conditions => "state = #{Cms::PUBLISHED}"
  scope :deleted, :conditions => "state = #{Cms::DELETED}"
  scope :onhold, :conditions => "state = #{Cms::ONHOLD}"

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

  scope :with_tags_from_user, lambda { |tags,user|
      {:conditions => [
          'contents.id IN (SELECT content_id
                             FROM users_contents_tags
                            WHERE user_id = ?
                              AND original_name IN (?))', user, tags]}
  }

  scope :recent, :conditions => "created_on >= now() - '3 months'::interval"
  scope :content_type_name, lambda { |name| {
            :conditions => ["content_type_id = (
                              SELECT id
                              FROM content_types
                              WHERE name = ?)", name]
        }
  }

  scope :of_interest_to, lambda {|user|
    # We need these 3 queries in order to find contents associated with
    # categories associated with the top level terms that the user has an
    # interest in.
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

  scope :content_type_names, lambda { |names| {
            :conditions => ["content_type_id IN (
                              SELECT id
                              FROM content_types
                              WHERE name IN (?))",
                              names]
        }
  }

  after_save do |m|
    m.contents_locks.clear if m.contents_locks
    old_url = m.url
    new_url = Routing.gmurl(m)
    if old_url != new_url # url has changed, let's update comments
      User.db_query(
          "UPDATE comments
              SET portal_id = #{m.portal_id}
            WHERE content_id = #{m.id}")
    end
  end

  before_save :check_changed_attributes
  belongs_to :clan
  belongs_to :game
  belongs_to :gaming_platform
  belongs_to :bazar_district
  belongs_to :user

  def self.final_decision_made(decision)
    puts "final decision!"
    content = Content.find(decision.context.fetch(:content_id))
    if Cms::NO_MODERATION_NEEDED_CONTENTS.include?(content.content_type.name)
      raise (
          "Received decision for content of type '#{content.content_type.name}'
          for which no moderation is needed.")
    end

    expected_class = "Publish#{content.content_type.name}"
    if decision.decision_type_class != expected_class
      raise (
          "Mismatch between decision_type_class and content_type:
          #{decision.decision_type_class} != #{expected_class}")
    end

    self.handle_publish_decision(decision, content)
  end

  def self.handle_publish_decision(decision, uniq)
    content = uniq.real_content
    if decision.final_decision_choice.name == Decision::BINARY_YES
      prev_state = content.state
      content.change_state(Cms::PUBLISHED, Ias.MrMan)
      if prev_state == Cms::PENDING
        self.create_alert_after_crowd_publishing_decision(uniq, "publicado")
      end
      decision.context[:result] = (
          "<a href=\"#{Routing.gmurl(content)}\">Ver contenido</a>")
      decision.save
    else
      prev_state = content.state
      content.change_state(Cms::DELETED, Ias.MrMan)
      if prev_state == Cms::PENDING
        self.create_alert_after_crowd_publishing_decision(uniq, "denegado")
      end
    end
  end

  def self.published_counts_by_user(user)
    out = {}
    User.db_query(
        "SELECT COUNT(*) AS cnt,
           (SELECT name
              FROM content_types
              WHERE id = contents.content_type_id) AS content_type_name
        FROM contents
        WHERE user_id = #{user.id}
        AND state = #{Cms::PUBLISHED}
        GROUP BY (
          SELECT name
          FROM content_types
          WHERE id = contents.content_type_id)").each do |row|
      out[row['content_type_name']] = row['cnt'].to_i
    end
    ContentType.find(:all).each do |content_type|
      out[content_type.name] ||= 0
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

  def self.create_alert_after_crowd_publishing_decision(uniq, action_taken)
    ttype, scope = Alert.fill_ttype_and_scope_for_content_report(uniq)
    content_url = Routing.url_for_content_onlyurl(uniq.real_content)
    Alert.create({
      :type_id => ttype,
      :scope => scope,
      :reporter_user_id => Ias.MrMan.id,
      :headline => (
          "#{Cms.faction_favicon(uniq)}<strong>
          <a href=\"#{content_url}\">#{uniq.real_content.resolve_html_hid}</a>
          </strong> #{action_taken}"),
    })
  end

  # Call this function if you want to change a content state regardless outside
  # of the moderation queue voting mechanism.
  def self.modify_content_state(content, user, new_state, reason=nil)
    uniq = content.unique_content

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
    ("Content: id: #{self.id}, content_type_id: #{self.content_type_id}," +
     " name: #{self.name}")
  end

  def resolve_portal_id
    # primero los fáciles
  end

  def top_tags
    self.terms.contents_tags.find(:all, :order => 'lower(name)')
  end

  def unlink_real_content
    self.update_attribute(:state, Cms::DELETED)
    self.terms.each do |term|
      term.resolve_last_updated_item
    end

    cls_name = Object.const_get(self.content_type.name)
    User.db_query("UPDATE #{ActiveSupport::Inflector::tableize(cls_name)}
                      SET unique_content_id = NULL
                    WHERE id = #{self.external_id}")
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
    rc = real_content
    g_id = rc.get_game_id
    if g_id != self.game_id
      self.game_id = g_id
    else
      p_id = rc.get_my_gaming_platform_id
      if p_id
        self.gaming_platform_id = p_id
      else # maybe bazar_district
        bd_id = rc.get_my_bazar_district_id
        self.bazar_district_id = bd_id if bd_id
      end
    end

    if self.state_changed? && self.state != Cms::PUBLISHED
      self.contents_recommendations.each { |cr| cr.destroy }
    end
    self.name = rc.resolve_hid if self.name != rc.resolve_hid
    self.is_public = rc.is_public?
    self.user_id = rc.user_id
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

  def real_content
    # devuelve el objeto real al que referencia
    @_cache_real_content ||= begin
      ctype = Object.const_get(self.content_type.name)
      ctype.send(:with_exclusive_scope) { ctype.find(self.external_id) }
      # NECESSARY because we use find_each in weekly.rb and there is a rails bug
      # (
      # https://rails.lighthouseapp.com/projects/8994/tickets/
      #   1267-methods-invoked-within-scope-procs-should-respect-the-scope-stack
      # )
    end
  end

  def clear_comments
    self.comments.clear
  end

  def locked_for_user?(user)
    mlock = cur_lock
    (mlock && mlock.user_id != user.id)
  end

  def cur_lock
    ContentsLock.find(:first, :conditions => ['content_id = ? and updated_on > now() - \'35 seconds\'::interval', self.id])
  end

  def lock(user)
    mlock = cur_lock
    if mlock && mlock.user_id != user.id
      raise AccessDenied
    elsif mlock
      mlock.save # touch updated_on
    else
      ContentsLock.delete_all("content_id = #{self.id}") # borramos si queda alguno viejo
      cl = ContentsLock.create({:content_id => self.id, :user_id => user.id})
      raise "lock  couldnt be created: #{cl.errors.full_messages_html}" unless cl
      # raise "lock created #{}"
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
    if Cms::NO_MODERATION_NEEDED_CONTENTS.include?(self.content_type.name)
      return
    end
    if self.content_type.name == "Image"
      content_name = (
          "<img src=\"/cache/thumbnails/i/85x60/#{self.real_content.file}\" />")
    else
      content_name = self.name
    end

    Decision.create({
      :decision_type_class => "Publish#{self.content_type.name}",
      :context => {
        :content_id => self.id,
        :content_name => self.name,
        :initiating_user_id => self.user_id,
      },
    })
  end
end
