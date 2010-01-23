class UsersPreference < ActiveRecord::Base
  belongs_to :user
  DEFAULTS = {
    :comments_autoscroll => 1,
    :interested_in => '',
    :looking_for => '',
    :quicklinks => [],
    :user_forums => [[], [], []],
    :public_ban_reason => ''
  }
  # WARNING usar clone!!!
  serialize :value
end
