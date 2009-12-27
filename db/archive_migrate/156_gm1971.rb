class Gm1971 < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table comments add column lastowner_version varchar;"
    slonik_execute "alter table comments add column lastedited_by_user_id int references users(id) match full;"
  end

  def self.down
  end
end
