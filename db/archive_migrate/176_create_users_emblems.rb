class CreateUsersEmblems < ActiveRecord::Migration
  def self.up
    slonik_execute "create table users_emblems (id serial primary key, created_on date not null default now()::date, user_id int references users match full, emblem varchar not null);"
    slonik_execute "create index users_emblems_user_id on users_emblems(user_id);"
    slonik_execute "create index users_emblems_created_on on users_emblems(created_on);"
  end

  def self.down
    drop_table :users_emblems
  end
end
