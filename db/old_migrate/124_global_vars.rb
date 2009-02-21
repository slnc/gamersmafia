class GlobalVars < ActiveRecord::Migration
  def self.up
    slonik_execute "create table global_vars(id serial primary key, online_anonymous int not null default 0, online_registered int not null default 0, svn_revision int);"
    execute "INSERT INTO global_vars(online_anonymous) VALUES(0);"
  end

  def self.down
  end
end
