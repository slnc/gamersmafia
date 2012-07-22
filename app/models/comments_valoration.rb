# -*- encoding : utf-8 -*-
class CommentsValoration < ActiveRecord::Base
  NEGATIVE = -1
  NEUTRAL = 0
  POSITIVE = 1

  after_create :reset_user_cache
  after_destroy :reset_users_daily_allocation
  after_save :reset_users_daily_allocation
  after_save :reset_comments_rating

  before_save :check_not_self
  before_save :init_randval

  belongs_to :comments_valorations_type
  belongs_to :user
  belongs_to :comment

  scope :negative, :conditions => "comments_valorations_type_id IN (SELECT id
      FROM comments_valorations_types WHERE direction = #{NEGATIVE})"

  scope :neutral, :conditions => "comments_valorations_type_id IN (SELECT id
      FROM comments_valorations_types WHERE direction = #{NEUTRAL})"

  scope :positive, :conditions => "comments_valorations_type_id IN (SELECT id
      FROM comments_valorations_types WHERE direction = #{POSITIVE})"

  scope :recent, :conditions => "created_on >= now() - '1 month'::interval"


  private
  def init_randval
    self.randval = Kernel.rand unless self.randval
  end

  def check_not_self
    self.user_id != comment.user_id
  end

  def reset_comments_rating
    self.comment.update_attribute(:cache_rating, nil)
    # TODO PERF hacer esto una vez al día solamente?
    self.comment.user.update_attribute(:comments_valorations_type_id, nil)
  end

  def reset_user_cache
    self.comment.user.update_attribute(:cache_valorations_weights_on_self_comments, nil)
  end

  def reset_users_daily_allocation
    self.user.update_attribute(:cache_remaining_rating_slots, nil)
  end
end
