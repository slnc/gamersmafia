class CreateUsersPreferences < ActiveRecord::Migration
  def self.up

    slonik_execute "create table users_preferences (id serial primary key, user_id int not null references users match full, name varchar not null, value varchar);"
    slonik_execute "create unique index users_preferences_user_id_name on users_preferences(user_id, name);"
  end

  def self.down
    drop_table :users_preferences
  end
end
