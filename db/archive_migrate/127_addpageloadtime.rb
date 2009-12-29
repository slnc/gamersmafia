class Addpageloadtime < ActiveRecord::Migration
  def self.up
   # slonik_execute "create table stats.pageloadtime(controller varchar, action varchar, time decimal(10,2), created_on timestamp not null default now(), id serial primary key not null unique);"
  end

  def self.down
  end
end
