# -*- encoding : utf-8 -*-
class UserLoginChange < ActiveRecord::Base
  belongs_to :user
  validates_presence_of [:old_login, :user_id]
  validates_format_of :old_login, :with => User::OLD_LOGIN_REGEXP
end
