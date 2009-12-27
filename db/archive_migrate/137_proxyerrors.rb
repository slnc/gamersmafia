class Proxyerrors < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table stats.general add column proxy_errors int;"
    slonik_execute "alter table stats.general add column new_factions int;"
    slonik_execute "alter table stats.pageloadtime add column http_status int;"
    slonik_execute "alter table stats.general add column http_404 int;"
    slonik_execute "alter table stats.general add column http_401 int;"
    slonik_execute "alter table stats.general add column http_500 int;"
  end

  def self.down
    
  end
end
