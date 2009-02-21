class CreateContentsRecommendations < ActiveRecord::Migration
  def self.up
    slonik_execute "create table contents_recommendations (id serial primary key, created_on timestamp not null default now(), sender_user_id int not null references users, receiver_user_id int not null references users match full, content_id int not null references contents match full, seen_on timestamp, marked_as_bad bool not null default 'f', confidence float, expected_rating smallint);"
    slonik_execute "create index contents_recommendations_receiver_user_id_marked_as_bad on contents_recommendations(receiver_user_id, marked_as_bad);"
    slonik_execute "create index contents_recommendations_sender_user_id on contents_recommendations(sender_user_id);"
    slonik_execute "create unique index contents_recommendations_content_id_sender_user_id_receiver_user_id on contents_recommendations(content_id, sender_user_id, receiver_user_id);"    
    slonik_execute "create index contents_recommendations_seen_on_content_id_receiver_user_id on contents_recommendations(content_id, receiver_user_id);"
  end

  def self.down
    drop_table :contents_recommendations
  end
end
