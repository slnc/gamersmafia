class AddIconToBazarDistrict < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table bazar_districts add column icon varchar;"
  end

  def self.down
  end
end
