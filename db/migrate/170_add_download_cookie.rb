class AddDownloadCookie < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table downloaded_downloads add column download_cookie varchar(32);"
  end

  def self.down
  end
end
