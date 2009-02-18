class AddMoreGeneralStats < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table stats.general add column new_clans int;"
    slonik_execute "alter table stats.general add column new_closed_topics int;"
    slonik_execute "alter table stats.general add column new_clans_portals int;"
  end

  def self.down
  end
end
