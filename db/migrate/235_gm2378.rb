class Gm2378 < ActiveRecord::Migration
  def self.up
     
    execute "insert into content_types(name) VALUES('RecruitmentAd');"
    
    slonik_execute "alter table recruitment_ads add column title varchar;"
    slonik_execute "alter table recruitment_ads rename message to main;"
    slonik_execute "alter table recruitment_ads alter column main type text;"
    
    slonik_execute "alter table recruitment_ads add column hits_anonymous int not null default 0;"
    slonik_execute "alter table recruitment_ads add column hits_registered int not null default 0;"
    slonik_execute "alter table recruitment_ads add column cache_rating smallint;"
    slonik_execute "alter table recruitment_ads add column cache_rated_times smallint;"
    slonik_execute "alter table recruitment_ads add column cache_comments_count int not null default 0;"
    slonik_execute "alter table recruitment_ads add column log varchar;"
    slonik_execute "alter table recruitment_ads add column state smallint not null default 0;"
    
    execute "update recruitment_ads set state = 2;"
    
    
    slonik_execute "alter table recruitment_ads add column cache_weighted_rank numeric(10, 2);"
    slonik_execute "alter table recruitment_ads add column closed bool not null default 'f';"
    slonik_execute "alter table recruitment_ads add column unique_content_id int references contents(id) match full;"
    
    # PENDIENTE EN BLACKWINGS
    # ---- script
    RecruitmentAd.find(:all).each do |rad|
      User.db_query("UPDATE recruitment_ads SET title = #{User.connection.quote(rad.OLDtitle)} WHERE id = #{rad.id}")
      rad.title = rad.OLDtitle
      rad.create_my_unique_content
      rad.link_to_root_term
    end
    
    slonik_execute "alter table recruitment_ads alter column title set not null;"
  end
  
  def self.down
  end
end
