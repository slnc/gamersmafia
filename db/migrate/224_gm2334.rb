class Gm2334 < ActiveRecord::Migration
  def self.up
    slonik_execute "create table terms(id serial primary key not null unique, name varchar not null, slug varchar not null, description varchar, parent_term_id int references terms match full, game_id int references games match full, platform_id int references platforms match full, bazar_district_id int references bazar_districts match full, clan_id int references clans match full);"
    slonik_execute "create table contents_terms(id serial primary key not null unique, content_id int not null references contents match full, term_id int not null references terms match full, created_on timestamp not null default now());"
    slonik_execute "alter table terms add column root_id int references terms(id) match full;"
    slonik_execute "alter table terms rename parent_term_id to parent_id;"
  end

  def self.down
  end
end
