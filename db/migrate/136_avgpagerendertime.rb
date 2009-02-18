class Avgpagerendertime < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table stats.general add column avg_page_render_time real;"
    slonik_execute "alter table stats.general add column users_generating_karma int;"
    slonik_execute "alter table stats.general add column karma_per_user real;"
    slonik_execute "alter table stats.general add column active_factions_portals int;"
    slonik_execute "alter table stats.general add column completed_competitions_matches int;"
    
    slonik_execute "alter table stats.general add column active_clans_portals int;"
  end

  def self.down
    
  end
end
