class AddCreatorUserIdToClan < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table clans add column creator_user_id int references users match full;"
    slonik_execute 'alter table users_actions drop constraint "users_actions_created_on_key";'
    slonik_execute 'create index users_actions_created_on on users_actions(created_on);'
  end
  
  def self.down
  end
end
