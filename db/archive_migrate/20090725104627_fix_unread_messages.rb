class FixUnreadMessages < ActiveRecord::Migration
  def self.up
	User.can_login.each do |u|
		Message.update_unread_count(u)
	end
  end

  def self.down
  end
end
