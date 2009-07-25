class Content < ActiveRecord::Base
  belongs_to :content_type
  before_destroy :clear_comments
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
  
  after_save do |m| 
    m.contents_locks.clear if m.contents_locks
    old_url = m.url 
    new_url = ApplicationController.gmurl(m)
    if old_url != new_url # url has changed, let's update comments
      User.db_query("UPDATE comments SET portal_id = #{m.portal_id} WHERE content_id = #{m.id}")
    end
  end
  before_save :check_changed_attributes
  observe_attr :state
  observe_attr :comments_count
  belongs_to :clan
  belongs_to :game
  belongs_to :platform
  belongs_to :bazar_district
  belongs_to :user
  
  before_destroy :unlink_real_content
  
  def resolve_portal_id
    # primero los fáciles
  end
  
  def top_tags
    self.terms.contents_tags.find(:all, :order => 'lower(name)')
  end
  
  def unlink_real_content
    # nos quitamos de last_updated_item_id si lo hay
    Term.find(:all, :conditions => ['last_updated_item_id = ?', self.id]).each do |t|
      t.recalculate_last_updated_item_id(self.id)
    end
    cls_name = Object.const_get(self.content_type.name)
    User.db_query("UPDATE #{ActiveSupport::Inflector::tableize(cls_name)} SET unique_content_id = NULL WHERE id = #{self.external_id}")
    true
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
    
    if self.slnc_changed?(:state) && self.state != Cms::PUBLISHED
      self.contents_recommendations.each { |cr| cr.destroy }
    end
    self.name = rc.resolve_hid if self.name != rc.resolve_hid
    self.is_public = rc.is_public?
    self.user_id = rc.user_id
    true
  end
  
  def my_faction
    Faction.find(:first, :conditions => "code = (SELECT code FROM games WHERE id = #{game_id})")
  end
  
  def real_content
    # devuelve el objeto real al que referencia
    @_cache_real_content ||= begin       
      ctype = Object.const_get(self.content_type.name)
      ctype.find(self.external_id)
    end
  end
  
  def clear_comments
    self.comments.clear
  end
  
  def locked_for_user?(user)
    mlock = cur_lock
     (mlock && mlock.user_id != user.id) ? true : false
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
    puts "#{self.content_type.name} no permite enlazar a root_terms" unless Cms::ROOT_TERMS_CONTENTS.include?(self.content_type.name)
    newt = [newt] unless newt.kind_of?(Array)
    existing = self.root_terms.collect { |t| t.id }
    to_del = existing - newt
    to_add = newt - existing
    root_terms_add_ids(to_add)
    to_del.each { |tid| self.contents_terms.find(:first, :conditions => ['term_id = ?', tid]).destroy }
  end
  
  def categories_terms_ids=(arg)
    puts "#{self.content_type.name} no permite enlazar a categories_terms" unless Cms::CATEGORIES_TERMS_CONTENTS.include?(self.content_type.name)
    newt = arg[0]
    taxonomy = arg[1]
    newt = [newt] unless newt.kind_of?(Array)
    existing = self.categories_terms(taxonomy).collect { |t| t.id }
    to_del = existing - newt
    to_add = newt - existing
    categories_terms_add_ids(to_add, taxonomy)
    to_del.each { |tid| self.contents_terms.find(:first, :conditions => ['term_id = ?', tid]).destroy }
  end
  
  def root_terms_add_ids(terms)
    puts "#{self.content_type.name} no permite enlazar a root_terms" unless Cms::ROOT_TERMS_CONTENTS.include?(self.content_type.name)
    terms = [terms] unless terms.kind_of?(Array)
    terms.each do |tid|
      t = Term.find_taxonomy(tid, nil)
      t.link(self) 
    end
  end
  
  def categories_terms_add_ids(terms, taxonomy)
    puts "#{self.content_type.name} no permite enlazar a categories_terms" unless Cms::CATEGORIES_TERMS_CONTENTS.include?(self.content_type.name)
    terms = [terms] unless terms.kind_of?(Array)
    terms.each do |tid|
      t = Term.find_taxonomy(tid, taxonomy)
      t.link(self) 
    end
  end
  
  def self.orphaned
    q_cts = Cms::CONTENTS_WITH_CATEGORIES.collect { |ctn| "'#{ctn}'"}
    #Content.find_by_sql("SELECT *
    #                      FROM contents
    #                     WHERE id IN (select a.id 
    #                                    from contents a 
    #                               left join contents_terms b on a.id = b.content_id 
    #                                   where a.clan_id IS NULL 
    #                                     and b.content_id is null 
    #                                     and content_type_id in (select id 
    #                                                               from content_types 
    #                                                              where name in (#{q_cts.join(',')})))
    #                  ORDER BY created_on")
    Content.find_by_sql("SELECT * 
                           FROM contents 
                          WHERE content_type_id in (select id from content_types where name in (#{q_cts.join(',')})) 
                            AND id not in (select id from contents_terms) 
                       ORDER BY id")
  end
end
