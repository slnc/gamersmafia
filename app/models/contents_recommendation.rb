class ContentsRecommendation < ActiveRecord::Base
  belongs_to :sender, :class_name => 'User', :foreign_key => 'sender_user_id'
  belongs_to :receiver, :class_name => 'User', :foreign_key => 'receiver_user_id'
  belongs_to :content
  validates_presence_of [:sender_user_id, :receiver_user_id, :content_id]
  
  validates_uniqueness_of :content_id, :scope => [:sender_user_id, :receiver_user_id]
  
  def mark_bad
    self.update_attributes(:marked_as_bad => true) unless self.marked_as_bad
  end
  
  def mark_seen
    self.update_attributes(:seen_on => Time.now) unless self.seen_on
  end
  
  def self.find_for_user(u)
    recs = self.find(:all, :conditions => ['receiver_user_id = ? AND seen_on IS NULL', u.id], :order => 'contents_recommendations.id DESC', :limit => 10, :include => [:content])
    seen_contents = []
    recs_f = []
    recs.each do |rec|
      recs_f << rec unless seen_contents.include?(rec.content_id)
      seen_contents << rec.content_id
    end
    recs_f
  end
end
