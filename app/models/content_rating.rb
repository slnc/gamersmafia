# -*- encoding : utf-8 -*-
class ContentRating < ActiveRecord::Base
  belongs_to :content
  belongs_to :user
  before_save :check_rating
  after_save :update_content_rating
  after_create :reset_users_daily_allocation
  after_destroy :reset_users_daily_allocation
  validates_uniqueness_of :user_id, :scope => :content_id

  protected
  def check_rating
    if self.rating < 1 then
      self.rating = 1
    elsif self.rating > 10 then
      self.rating = 10
    end
  end

  def reset_users_daily_allocation
    if self.user_id
      User.db_query("UPDATE users SET cache_remaining_rating_slots = NULL WHERE id = #{self.user_id}")
    end
  end

  def update_content_rating
    GmSys.job("Content.find(#{self.content_id}).real_content.clear_rating_cache")
  end
end
