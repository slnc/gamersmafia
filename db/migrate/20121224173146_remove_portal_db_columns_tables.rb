class RemovePortalDbColumnsTables < ActiveRecord::Migration
  def up
    raise "manually run this after migration is complete"
    execute "drop table ads_slots_portals;"
    execute "drop table portal_headers;"
    execute "drop table factions_portals;"
    execute "drop table portals_skins;"
    execute "drop table portal_hits;"
    execute "drop table portals;"
    execute "alter table stats.pageviews drop column portal_id;"
    execute "alter table comments drop column portal_id;"
    execute "alter table contents drop column portal_id;"
    execute "alter table outstanding_entities drop column portal_id;"
    execute "alter table potds drop column portal_id;"
    execute "alter table stats.ads drop column portal_id;"
    execute "alter table stats.pageloadtime drop column portal_id;"
    execute "drop table stats.portals;"
    execute "drop table users_karma_daily_by_portal;"
    execute "alter table global_vars drop column portals_updated_on;"
    execute "alter table users drop column default_portal;"
    execute "alter table archive.pageviews drop column portal_id;"
    execute "alter table stats.general drop column new_clans_portals;"
    execute "alter table stats.general drop column active_factions_portals;"
    execute "alter table stats.general drop column active_clans_portals;"
  end

  def down
  end
end
