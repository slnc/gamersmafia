# -*- encoding : utf-8 -*-
class ContentsRecommendation < ActiveRecord::Base
  belongs_to :sender, :class_name => 'User', :foreign_key => 'sender_user_id'
  belongs_to :receiver, :class_name => 'User', :foreign_key => 'receiver_user_id'
  belongs_to :content
  before_create :check_if_already_recommended
  validates_presence_of [:sender_user_id, :receiver_user_id, :content_id]
  validates_uniqueness_of :content_id, :scope => [:receiver_user_id]

  def check_if_already_recommended
    recommended_already = ContentsRecommendation.count(
        :conditions => [
          'receiver_user_id = ? AND content_id = ? AND seen_on IS NOT NULL',
          self.receiver_user_id, self.content_id]) > 0
    visited_already = TrackerItem.count(
        :conditions => ['user_id = ? AND content_id = ?',
                        self.receiver_user_id, self.content_id]) > 0
    !(recommended_already || visited_already)
  end

  def mark_bad
    return if self.marked_as_bad
    self.update_attributes(:marked_as_bad => true)
  end

  def mark_seen
    self.update_attributes(:seen_on => Time.now) if !self.seen_on
    ContentsRecommendation.find(
        :all,
        :conditions => [
            'receiver_user_id = ? AND content_id = ? AND seen_on IS NULL',
            self.receiver_user_id, self.content_id]).each do |cr|
      cr.update_attributes(:seen_on => cr.created_on)
    end
  end

  def self.find_for_user(u)
    recs = self.find(
        :all,
        :conditions => ["receiver_user_id = ? AND
                         seen_on IS NULL AND
                         contents.state = #{Cms::PUBLISHED}", u.id],
        :order => 'contents_recommendations.confidence DESC',
        :limit => 10,
        :include => [:content])
    seen_contents = []
    recs_f = []
    recs.each do |rec|
      next if !rec
      recs_f << rec unless seen_contents.include?(rec.content_id)
      seen_contents << rec.content_id
    end
    recs_f
  end
end
