class CommentsValoration < ActiveRecord::Base
  belongs_to :comments_valorations_type
  belongs_to :user
  belongs_to :comment
  after_save :reset_users_daily_allocation
  after_save :reset_comments_rating
  after_destroy :reset_users_daily_allocation
  
  before_save :check_not_self
  after_create :reset_user_cache 

  named_scope :recent, :conditions => 'created_on >= now() - \'1 month\'::interval'
  
  private
  def reset_user_cache
    self.comment.user.update_attributes(:cache_valorations_weights_on_self_comments => nil)
  end
  
  def check_not_self
    user_id != comment.user_id
  end
  
  def reset_users_daily_allocation
    User.db_query("UPDATE users SET cache_remaining_rating_slots = NULL WHERE id = #{self.user_id}")
  end
  
  def reset_comments_rating
    User.db_query("UPDATE comments SET cache_rating = NULL where id = #{self.comment_id}")
    # TODO PERF hacer esto una ve al día solamente?
    User.db_query("UPDATE users SET comments_valorations_type_id = NULL WHERE id = #{comment.user_id}")
  end
end
