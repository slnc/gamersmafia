class RenamePlatforms < ActiveRecord::Migration
  def up
    execute "alter table platforms rename to gaming_platforms;"
    execute "alter table contents rename platform_id to gaming_platform_id;"
    execute "alter table factions rename is_platform to is_gaming_platform;"
    execute "alter table games_platforms rename to games_gaming_platforms;"
    execute "alter table games_gaming_platforms rename platform_id to gaming_platform_id;"
    execute "alter table platforms_users rename to gaming_platforms_users;"
    execute "alter table gaming_platforms_users rename platform_id to gaming_platform_id;"
    execute "alter table terms rename platform_id to gaming_platform_id;"
  end

  def down
  end
end
