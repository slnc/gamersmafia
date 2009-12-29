class Groups < ActiveRecord::Migration
  def self.up
    slonik_execute "create table groups(id serial primary key, name varchar not null unique, created_on timestamp not null default now(), description varchar, owner_user_id int references users match full);"
    slonik_execute "create table groups_messages(id serial primary key, created_on timestamp not null default now(), title varchar, main varchar, parent_id int references groups_messages match full, root_id int references groups_messages match full, user_id int references users match full);"
  end

  def self.down
    drop_table :groups
  end
end
