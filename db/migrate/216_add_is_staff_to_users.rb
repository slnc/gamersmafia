class AddIsStaffToUsers < ActiveRecord::Migration
  def self.up
    #slonik_execute "alter table users add column is_staff bool not null default false;"
    User.find(:all, :conditions => "is_hq = 't' OR id IN (SELECT user_id FROM users_roles) OR id IN (SELECT user_id FROM competitions_admins) OR id IN (SELECT user_id FROM competitions_supervisors)").each do |u|
      u.check_is_staff
    end
  end

  def self.down
  end
end
