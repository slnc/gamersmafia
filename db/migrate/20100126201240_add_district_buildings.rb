class AddDistrictBuildings < ActiveRecord::Migration
  def self.up
    execute "alter table bazar_districts add column building_top varchar;"
    execute "alter table bazar_districts add column building_middle varchar;"
    execute "alter table bazar_districts add column building_bottom varchar;"
  end

  def self.down
  end
end