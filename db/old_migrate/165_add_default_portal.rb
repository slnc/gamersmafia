class AddDefaultPortal < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table users add column default_portal varchar;"
  end

  def self.down
  end
end
