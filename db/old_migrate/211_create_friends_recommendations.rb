class CreateFriendsRecommendations < ActiveRecord::Migration
  def self.up
    slonik_execute "create table friends_recommendations(id serial primary key not null unique, user_id int references users match full not null, recommended_user_id int references users match full not null, created_on timestamp not null default now(), updated_on timestamp, added_as_friend bool);"
    slonik_execute "create unique index friends_recommendations_uniq on friends_recommendations(user_id, recommended_user_id);"
    slonik_execute "create index friends_recommendations_user_id_undecided on friends_recommendations(user_id, added_as_friend);"
  end

  def self.down
    drop_table :friends_recommendations
  end
end
