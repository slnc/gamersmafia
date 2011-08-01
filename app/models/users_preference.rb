class UsersPreference < ActiveRecord::Base
  belongs_to :user
  DEFAULTS = {
    :comments_autoscroll => 1,
    :looking_for => String,
    :quicklinks => Array,
    :user_forums => Array,
    :public_ban_reason => String
  }

  serialize :value
end
