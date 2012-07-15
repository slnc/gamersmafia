# -*- encoding : utf-8 -*-
class ContentsRecommendation < ActiveRecord::Base
  belongs_to :sender, :class_name => 'User', :foreign_key => 'sender_user_id'
  belongs_to :receiver, :class_name => 'User', :foreign_key => 'receiver_user_id'
  belongs_to :content
  validates_presence_of [:sender_user_id, :receiver_user_id, :content_id]

  before_create :check_if_already_recommended
  validates_uniqueness_of :content_id, :scope => [:sender_user_id, :receiver_user_id]

  def check_if_already_recommended
    self.seen_on = Time.now if ContentsRecommendation.count(:conditions => ['receiver_user_id = ? AND content_id = ? AND seen_on IS NOT NULL', self.receiver_user_id, self.content_id]) > 0
    true
  end

  def mark_bad
    self.update_attributes(:marked_as_bad => true) unless self.marked_as_bad
  end

  def mark_seen
    self.update_attributes(:seen_on => Time.now) unless self.seen_on
    ContentsRecommendation.find(:all, :conditions => ['receiver_user_id = ? AND content_id = ? AND seen_on IS NULL', self.receiver_user_id, self.content_id]).each do |cr|
      cr.update_attributes(:seen_on => cr.created_on)
    end
  end

  def self.find_for_user(u)
    recs = self.find(:all, :conditions => ['receiver_user_id = ? AND seen_on IS NULL', u.id], :order => 'contents_recommendations.id DESC', :limit => 10, :include => [:content])
    seen_contents = []
    recs_f = []
    recs.each do |rec|
      next unless rec
      recs_f << rec unless seen_contents.include?(rec.content_id)
      seen_contents << rec.content_id
    end
    recs_f
  end
end
