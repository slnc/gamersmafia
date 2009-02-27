class Gm2403 < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table questions add column answer_selected_by_user_id int references users match full;"
    
    slonik_execute "alter table stats.users_daily_stats add column popularity int;"
    slonik_execute "alter table users add column cache_popularity int;"
    
    slonik_execute "create table stats.clans_daily_stats(id serial primary key, clan_id int references clans match full, created_on date not null, popularity int);"
    slonik_execute "create index clans_daily_stats_clan_id_created_on on stats.clans_daily_stats(clan_id, created_on);"
    slonik_execute "alter table clans add column cache_popularity int;"
    slonik_execute "alter table clans add column ranking_popularity_pos int;"
  end

  def self.down
  end
end
