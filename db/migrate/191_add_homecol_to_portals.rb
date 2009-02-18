class AddHomecolToPortals < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table portals add factions_portal_home varchar;"
    # execute "UPDATE portals SET factions_portal_home = 'fps' WHERE "
  end

  def self.down
  end
end