class CreateUsersActions < ActiveRecord::Migration
  def self.up
    
    slonik_execute "create table users_actions(id serial primary key not null unique, created_on timestamp not null unique, user_id int references users match full, type_id int not null, data varchar);"
  end

  def self.down
    drop_table :users_actions
  end
end
