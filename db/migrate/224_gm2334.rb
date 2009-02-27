class Gm2334 < ActiveRecord::Migration
  def self.up
    slonik_execute "create table terms(id serial primary key not null unique, name varchar not null, slug varchar not null, description varchar, parent_term_id int references terms match full, game_id int references games match full, platform_id int references platforms match full, bazar_district_id int references bazar_districts match full, clan_id int references clans match full, contents_count int not null default 0, last_updated_item_id int references contents);"
    slonik_execute "create table contents_terms(id serial primary key not null unique, content_id int not null references contents match full, term_id int not null references terms match full, created_on timestamp not null default now());"
    slonik_execute "alter table terms add column root_id int references terms(id) match full;"
    slonik_execute "alter table terms rename parent_term_id to parent_id;"
    slonik_execute "alter table terms add column taxonomy varchar;"
    slonik_execute "create index terms_slug_uniq on terms(game_id, bazar_district_id, platform_id, clan_id, taxonomy, parent_id, slug);"
    slonik_execute "create index terms_name_uniq on terms(game_id, bazar_district_id, platform_id, clan_id, taxonomy, parent_id, name);"
    slonik_execute "create unique index contents_terms_uniq on contents_terms(content_id, term_id);"
    slonik_execute "create index contents_terms_content_id on contents_terms(content_id);"
    slonik_execute "create index contents_terms_term_id on contents_terms(term_id);"
    slonik_execute "alter table news alter column news_category_id drop not null;"
    slonik_execute "alter table downloads alter column downloads_category_id drop not null;"
    slonik_execute "alter table columns alter column columns_category_id drop not null;"
    slonik_execute "alter table demos alter column demos_category_id drop not null;"
    slonik_execute "alter table topics alter column topics_category_id drop not null;"
    slonik_execute "alter table images alter column images_category_id drop not null;"
    slonik_execute "alter table interviews alter column interviews_category_id drop not null;"
    slonik_execute "alter table tutorials alter column tutorials_category_id drop not null;"
    slonik_execute "alter table polls alter column polls_category_id drop not null;"
    slonik_execute "alter table bets alter column bets_category_id drop not null;"
    slonik_execute "alter table reviews alter column reviews_category_id drop not null;"
    slonik_execute "alter table events alter column events_category_id drop not null;"
    slonik_execute "alter table questions alter column questions_category_id drop not null;"
    
    
    slonik_execute "alter table news add column unique_content_id int references contents;"
    slonik_execute "alter table images add column unique_content_id int references contents;"
    slonik_execute "alter table events add column unique_content_id int references contents;"
    slonik_execute "alter table downloads add column unique_content_id int references contents;"
    slonik_execute "alter table demos add column unique_content_id int references contents;"
    slonik_execute "alter table tutorials add column unique_content_id int references contents;"
    slonik_execute "alter table interviews add column unique_content_id int references contents;"
    slonik_execute "alter table polls add column unique_content_id int references contents;"
    slonik_execute "alter table bets add column unique_content_id int references contents;"
    slonik_execute "alter table columns add column unique_content_id int references contents;"
    slonik_execute "alter table coverages add column unique_content_id int references contents;"
    slonik_execute "alter table questions add column unique_content_id int references contents;"
    slonik_execute "alter table reviews add column unique_content_id int references contents;"
    slonik_execute "alter table funthings add column unique_content_id int references contents;"
    slonik_execute "alter table topics add column unique_content_id int references contents;"
    slonik_execute "alter table blogentries add column unique_content_id int references contents;"
  end
  
  def self.down
  end
end
