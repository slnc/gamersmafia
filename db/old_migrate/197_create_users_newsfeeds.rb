class CreateUsersNewsfeeds < ActiveRecord::Migration
  def self.up
    slonik_execute "create table users_newsfeeds(id serial primary key not null unique, created_on timestamp not null unique, user_id int references users match full, summary varchar not null, users_action_id int references users_actions match full);"
  end

  def self.down
    drop_table :users_newsfeeds
  end
end
