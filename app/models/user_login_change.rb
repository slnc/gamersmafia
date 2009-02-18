class UserLoginChange < ActiveRecord::Base
  belongs_to :user
  validates_presence_of [:old_login, :user_id]
  validates_format_of :old_login, :with => User::LOGIN_REGEXP
end
