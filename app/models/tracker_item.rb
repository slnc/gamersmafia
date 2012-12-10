# -*- encoding : utf-8 -*-
class TrackerItem < ActiveRecord::Base
  belongs_to :user
  belongs_to :content

  after_create :check_if_recommended
  scope :updated

  def self.forget_old_tracker_items
    User.db_query(
        "INSERT INTO archive.tracker_items (
           SELECT *
           FROM public.tracker_items
           WHERE lastseen_on < now() - '6 months'::interval)")
    User.db_query(
        "DELETE FROM tracker_items
         WHERE lastseen_on < now() - '6 months'::interval")
  end

  def self.updated_for_user(someuser, only_new, limit='50')
    q_only = only_new ? "AND b.lastseen_on < a.updated_on " : ''
    items = User.db_query(
        "SELECT a.id,
           a.updated_on
         FROM contents a
         JOIN tracker_items b on a.id = b.content_id
         WHERE b.user_id = #{someuser.id}
         AND b.is_tracked = 't'
         AND a.state = #{Cms::PUBLISHED}
         #{q_only}
         ORDER BY a.updated_on DESC LIMIT #{limit}")
    joined_content_ids = items.collect {|dbr| dbr['id'].to_s }
    Content.published.find(
        :all,
        :conditions => ["id IN (?)", joined_content_ids],
        :order => "updated_on DESC")
  end

  def check_if_recommended
    ContentsRecommendation.find(
        :all,
        :conditions => [
            'receiver_user_id = ? AND content_id = ? AND seen_on IS NULL',
            self.user_id,
            self.content_id]).each do |ti|
      ti.mark_seen
    end
  end
end
