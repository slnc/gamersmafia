class Content < ActiveRecord::Base
  belongs_to :content_type
  before_destroy :clear_comments
  has_many :comments, :dependent => :destroy
  has_many :contents_versions, :dependent => :destroy
  has_many :content_ratings, :dependent => :destroy
  has_many :tracker_items, :dependent => :destroy
  has_many :contents_locks, :dependent => :destroy
  has_many :publishing_decisions
  has_many :terms, :through => :content_terms
  
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
  belongs_to :clan
  belongs_to :game
  belongs_to :platform
  belongs_to :bazar_district
  belongs_to :user
  
  def resolve_portal_id
    # primero los fáciles
    
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
end
