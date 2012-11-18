class UpdateTermsTaxonomies < ActiveRecord::Migration
  def up
    execute "update terms set taxonomy = 'Homepage' WHERE slug IN ('arena', 'bazar', 'gm');"
    execute "update terms set taxonomy = 'Game' WHERE parent_id IS NULL AND game_id IS NOT NULL;"
    execute "update terms set taxonomy = 'GamingPlatform' WHERE parent_id IS NULL AND gaming_platform_id IS NOT NULL;"
    execute "update terms set taxonomy = 'BazarDistrict' WHERE parent_id IS NULL AND bazar_district_id IS NOT NULL;"
    execute "update terms set taxonomy = 'Clan' WHERE parent_id IS NULL AND clan_id IS NOT NULL;"
    execute "update terms set taxonomy='ContentsTag' where slug='gmversion';"
    execute "alter table terms alter column taxonomy set not null;"
  end

  def down
  end
end
