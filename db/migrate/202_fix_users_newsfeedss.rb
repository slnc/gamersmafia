class FixUsersNewsfeedss < ActiveRecord::Migration
  def self.up
slonik_execute 'alter table users_newsfeeds drop constraint "users_newsfeeds_created_on_key";' 
slonik_execute "create index users_newsfeeds_created_on on users_newsfeeds(created_on);"
  end

  def self.down
  end
end
