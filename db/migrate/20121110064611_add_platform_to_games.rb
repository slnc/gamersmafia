class AddPlatformToGames < ActiveRecord::Migration
  def change
    execute "alter table games add column gaming_platform_id int references gaming_platforms;"
    execute "update games set gaming_platform_id = (select id from gaming_platforms where code='pc');"
    execute "alter table games alter column gaming_platform_id set not null;"
    execute "create index games_gaming_platform on games(gaming_platform_id);"
  end
end
