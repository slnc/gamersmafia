class PageviewsArchive < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table sent_emails drop column body;"
    slonik_execute "create table archive.pageviews (like stats.pageviews);"
  end

  def self.down
  end
end
