# -*- encoding : utf-8 -*-
class UsersPreference < ActiveRecord::Base
  belongs_to :user
  DEFAULTS = {
    :comments_autoscroll => 1,
    :looking_for => String,
    :public_ban_reason => String,
    :quicklinks => Array,
    :show_all_comments => 0,
    :user_forums => Array,
  }

  serialize :value
end
