class CreateFriendships < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table users add column has_new_friend_requests bool not null default 'f';"
  end

  def self.down
    
  end
end
