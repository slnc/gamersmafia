class CreateRecruitmentAds < ActiveRecord::Migration
  def self.up
    slonik_execute "create table recruitment_ads(id serial primary key not null unique, created_on timestamp not null default now(), updated_on timestamp not null default now(), user_id int not null references users match full, clan_id int references clans match full, game_id int not null references games, levels varchar, country_id int references countries match full);"
  end

  def self.down
    drop_table :recruitment_ads
  end
end
