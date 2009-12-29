class AddUserToIpban < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table ip_bans int add column user_id references users match full;"
    execute "update ip_bans set user_id = 1;"
  end

  def self.down
  end
end
