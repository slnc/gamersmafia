class UsersPreference < ActiveRecord::Base
  belongs_to :user
  DEFAULTS = {
    :comments_autoscroll => 1,
    :interested_in => '',
    :looking_for => '',
    :quicklinks => [],
    :user_forums => [[], [], []],
  }
  # WARNING usar clone!!!
  serialize :value
end
