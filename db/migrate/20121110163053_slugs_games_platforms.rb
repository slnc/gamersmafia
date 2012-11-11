class SlugsGamesPlatforms < ActiveRecord::Migration
  def up
    execute "alter table games rename code to slug;"
    execute "alter table gaming_platforms rename code to slug;"
    execute "alter table gaming_platforms add column has_faction bool not null default 'f';"
    execute "update gaming_platforms set has_faction = 't';"
    execute "create unique index games_name_platform on games(name, gaming_platform_id);"
    execute "alter table games drop constraint games_name_key;"
    execute "alter table bazar_districts rename code to slug;"
  end

  def down
  end
end
