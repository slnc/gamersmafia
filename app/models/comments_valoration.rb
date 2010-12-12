class CommentsValoration < ActiveRecord::Base
  POSITIVE = 1
  NEGATIVE = -1
  NEUTRAL = 0
  
  after_create :reset_user_cache  
  after_destroy :reset_users_daily_allocation
  after_save :reset_users_daily_allocation
  after_save :reset_comments_rating
  
  before_save :check_not_self
  
  belongs_to :comments_valorations_type
  belongs_to :user
  belongs_to :comment
      
  named_scope :negative, :conditions => "comments_valorations_type_id IN (SELECT id 
      FROM comments_valorations_types WHERE direction = #{NEGATIVE})"
      
  named_scope :neutral, :conditions => "comments_valorations_type_id IN (SELECT id 
      FROM comments_valorations_types WHERE direction = #{NEUTRAL})"

  named_scope :positive, :conditions => "comments_valorations_type_id IN (SELECT id 
      FROM comments_valorations_types WHERE direction = #{POSITIVE})"

  named_scope :recent, :conditions => "created_on >= now() - '1 month'::interval"

  private
  def reset_user_cache
    self.comment.user.update_attribute(:cache_valorations_weights_on_self_comments, nil)
  end
  
  def check_not_self
    user_id != comment.user_id
  end
  
  def reset_users_daily_allocation
    self.user.update_attribute(:cache_remaining_rating_slots, nil)
  end
  
  def reset_comments_rating
    self.comment.update_attribute(:cache_rating, nil)
    # TODO PERF hacer esto una ve al día solamente?
    self.comment.user.update_attribute(:comments_valorations_type_id, nil)
  end
end
