# -*- encoding : utf-8 -*-
class Content < ActiveRecord::Base
  belongs_to :content_type
  before_destroy :clear_comments
  before_destroy :unlink_real_content
  has_many :comments, :dependent => :destroy
  has_many :contents_versions, :dependent => :destroy
  has_many :content_ratings, :dependent => :destroy
  has_many :tracker_items, :dependent => :destroy
  has_many :contents_locks, :dependent => :destroy
  has_many :publishing_decisions
  has_many :contents_recommendations, :dependent => :destroy
  has_many :terms, :through => :contents_terms
  has_many :contents_terms, :dependent => :destroy
  has_many :users_contents_tags, :dependent => :destroy

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
  belongs_to :platform
  belongs_to :bazar_district
  belongs_to :user

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
      p_id = rc.get_my_platform_id
      if p_id
        self.platform_id = p_id
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
      :conditions => "code = (SELECT code FROM games WHERE id = #{game_id})")
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

  def linked_terms(taxonomy=nil)
    if taxonomy.nil?
      self.terms.find(:all)
    elsif taxonomy == 'NULL'
      self.terms.find(:all, :conditions => 'taxonomy IS NULL', :order => 'created_on')
    else
      self.terms.find(:all, :conditions => ["taxonomy = ?", taxonomy], :order => 'created_on')
    end
  end

  def root_terms
    self.linked_terms('NULL')
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
      t = Term.find_taxonomy(tid, nil)
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
end
