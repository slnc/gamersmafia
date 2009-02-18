class AddDownloadsCountToDaily < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table stats.general add column downloaded_downloads_count int;"
    
    execute "update stats.general set downloaded_downloads_count = (select count(*) from downloaded_downloads WHERE date_trunc('day', downloaded_downloads.created_on) = date_trunc('day', stats.general.created_on)) WHERE created_on >= (select min(created_on) from downloaded_downloads);"
  end

  def self.down
  end
end
