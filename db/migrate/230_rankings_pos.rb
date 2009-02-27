class RankingsPos < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table users add column ranking_karma_pos int;"
    slonik_execute "alter table users add column ranking_faith_pos int;"
    slonik_execute "alter table users add column ranking_popularity_pos int;"
    slonik_execute "create table stats.users_daily_stats(id serial primary key not null unique, user_id int not null references users match full, created_on date not null, karma int, faith int);"
  end

  def self.down
  end
end
