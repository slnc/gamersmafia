class RankingsPos < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table users add column ranking_karma_pos int;"
    slonik_execute "alter table users add column ranking_faith_pos int;"
    slonik_execute "alter table users add column ranking_popularity_pos int;"
    slonik_execute "create table stats.users_daily_stats(id serial primary key not null unique, user_id int not null references users match full, created_on date not null, karma int, faith int);"
    slonik_execute "create index users_daily_stats_user_id_created_on on stats.users_daily_stats(user_id, created_on);"
    
    slonik_execute "create index refered_hits_user_id on refered_hits(user_id); analyze refered_hits;"
    execute "delete from refered_hits where user_id not in (select id from users);"
    slonik_execute "alter table refered_hits add foreign key (user_id) references users match full;"
  end

  def self.down
  end
end
