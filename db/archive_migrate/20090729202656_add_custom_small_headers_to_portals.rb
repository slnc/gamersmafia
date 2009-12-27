class AddCustomSmallHeadersToPortals < ActiveRecord::Migration
  def self.up
	slonik_execute "ALTER TABLE portals ADD COLUMN small_header varchar;"
  end

  def self.down
  end
end
