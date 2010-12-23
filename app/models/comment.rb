
#i = 0.0
#count = Comment.count
#prev = nil
#Comment.find_each do |comment|
#  begin
#    comment.download_remotes
#  rescue
#    puts "ERROR DOWNLOADING imgs para #{comment.id}"
#  end
#  i += 1
#  if prev != (i / count * 100).to_i && ((i / count) * 100).to_i * 10 == ((i / count) * 1000).to_i
#    puts (i / count * 100).to_i
#    prev = (i / count * 100).to_i
#  end
#end

class Comment < ActiveRecord::Base
  belongs_to :content
  belongs_to :user
  after_create :do_after_create
  after_create :schedule_image_parsing
  after_save :schedule_ne_references_calculation
  
  belongs_to :lastedited_by, :class_name => 'User', :foreign_key => 'lastedited_by_user_id'
  has_many :comments_valorations, :dependent => :destroy
  
  before_save :truncate_long_comments
  before_save :set_portal_id_based_on_content
  before_save :check_copy_if_changing_lastedited_by_user_id
  serialize :cache_rating
  
  observe_attr :lastedited_by_user_id
  observe_attr :comment
  
  def regenerate_ne_references(users=[])
    NeReference.find(:all, :conditions => ['referencer_class = \'Comment\' AND referencer_id = ?', self.id]).each { |ne| ne.destroy }
    
    if users == []
      users = {}
      User.db_query("SELECT id, lower(login) as login FROM users where login_is_ne_unfriendly = 'f'").each do |dbu|
        users[dbu['login']] ||= []
        users[dbu['login']]<< ['User', dbu['id'].to_i]
      end
      
      User.db_query("SELECT user_id, lower(old_login) as old_login FROM user_login_changes").each do |dbu| 
        users[dbu['old_login']] ||= []
        users[dbu['old_login']]<< ['User', dbu['user_id'].to_i]
      end
      
      User.db_query("SELECT id, lower(tag) as tag FROM clans").each do |dbu| 
        users[dbu['tag']] ||= []
        users[dbu['tag']]<< ['Clan', dbu['id'].to_i]
      end
    end
    
    # users = User.db_query("SELECT login FROM users").collect { |dbu| dbu['login'].downcase } if users == []
    references = self.comment.slnc_tokenize & users.keys
    ne_refs = []
    references.uniq.each do |ref|
      # puts "-- ref: #{ref}"
      # puts ref, users[ref], users[ref][1]
      
      ne_refs<< NeReference.create(:entity_class => users[ref][0][0], :entity_id => users[ref][0][1], :referencer_class => 'Comment', :referencer_id => self.id, :referenced_on => self.created_on)
    end
    ne_refs
  end
  
  def schedule_image_parsing
    GmSys.job("Comment.find(#{self.id}).download_remotes")
  end
  
  def schedule_ne_references_calculation
    GmSys.job("Comment.find(#{self.id}).regenerate_ne_references")
  end
  
  def download_remotes
    new_t = Cms.download_and_rewrite_bb_imgs(self.comment, "comments/#{self.id % 1000}/#{self.id % 100}")
    self.update_attributes(:comment => new_t) if new_t != self.comment
  end
  
  def check_copy_if_changing_lastedited_by_user_id
    if slnc_changed?(:lastedited_by_user_id) && self.lastedited_by_user_id != self.user_id && (slnc_changed_old_values[:lastedited_by_user_id].nil? || slnc_changed_old_values[:lastedited_by_user_id] == self.user_id)
      self.lastowner_version = self.slnc_changed_old_values[:comment]
    elsif self.lastedited_by_user_id == self.user_id
      self.lastowner_version =  nil
    end
    
    true
  end
  
  def mark_as_deleted
    del_karma
    
    # update last_commented_on
    u = self.user
    last_comment = Comment.find_by_user_id(u.id, :conditions => 'deleted = \'f\'', :order => 'created_on DESC')
    u.lastcommented_on = last_comment ? last_comment.created_on : nil
    u.save
    
    # update counters
    User.decrement_counter('comments_count', self.user_id)
    Content.decrement_counter('comments_count', self.content_id)
    self.content.terms.each do |t| 
      t.recalculate_counters
    end
    self.content.real_content.class.decrement_counter('cache_comments_count', self.content.real_content.id)
    
    self.deleted = true
    self.save
  end
  
  def set_portal_id_based_on_content
    self.portal_id = self.content.portal_id  
  end
  
  def truncate_long_comments
    self.comment = self.comment[0..5999] if self.comment.length > 6000
    true
  end
  
  def do_after_create
    add_karma
    self.user.update_attributes(:lastcommented_on => self.created_on)
    # TODO bj lightweight needed GmSys.job("Comment.find(#{self.id}).notify_trackers")
    GmSys.job("Comment.find(#{self.id}).notify_trackers")
  end
  
  def notify_trackers
    self.content.tracker_items.find(:all, :conditions => 'is_tracked = \'t\'', :include => [:user]).each do |t|
      u = t.user
      if u.id != self.user_id and u.notifications_trackerupdates and (t.notification_sent_on.nil? or t.lastseen_on > t.notification_sent_on) then
        Notification.deliver_trackerupdate(u, { :content => self.content.real_content })
        t.notification_sent_on = Time.now
        t.save
      end
    end
  end

  def update_default_comments_valorations_weight
	  positive = self.comments_valorations_ratings.recent.count(:conditions => 'comments_valorations_type_id IN (select id from comments_valorations_types where direction = 1)')
	  negative = self.comments_valorations_ratings.recent.count(:conditions => 'comments_valorations_type_id IN (select id from comments_valorations_types where direction = -1)')
	  neutral = self.comments_valorations_ratings.recent.count(:conditions => 'comments_valorations_type_id IN (select id from comments_valorations_types where direction = 0)')
          ratio = negative.to_f/(positive + negative + neutral)
	  if ratio > 0.6
		   default = 0.0
	  else
		  default = 1.0
	  end
	  self.update_attributes(:default_comments_valorations_weight => default)
  end
  
  def add_karma
    Karma.add_karma_after_comment_is_created(self)
  end
  
  def del_karma
    Karma.del_karma_after_comment_is_deleted(self)  
  end
  
  def rate(user, rating)
    weight = Comments.get_user_weight_in_comment(user, self)
    prev = comments_valorations.find(:first, :conditions => ['user_id = ?', user.id])
    if prev.nil?
      prev = comments_valorations.create({:user_id => user.id, :comments_valorations_type_id => rating.id, :weight => weight})
    else
      prev.comments_valorations_type_id = rating.id
      prev.weight = weight
      prev.save
    end
    
    if !has_comments_valorations  # TODO: por qué has_comments_valorations? devuelve true????
      self.has_comments_valorations = true
      self.save
    end
  end
  
  def get_rating
    if self.cache_rating.nil?    
      self.cache_rating = Comments.get_ratings_for_comments([self.id])
      self.save
    end
    self.cache_rating
  end
  
  def validate
    if new_record? and Comment.find(:first, :conditions => ['host = ? and comment = ? and user_id = ? and content_id = ?', self.host, self.comment, self.user_id, self.content_id])
      self.errors.add('text', 'Ya existe un comentario idéntico en este contenido.')
      return false
    end
    
    c = self.content
    if c.nil? or c.real_content.nil?
      self.errors.add_to_base('El contenido al que se refiere este comentario ya no existe')
      return false
    end
  end
  
  validates_presence_of :comment, :message => 'no puede estar en blanco'
  validates_presence_of :user_id, :message => 'no puede estar en blanco'
end
