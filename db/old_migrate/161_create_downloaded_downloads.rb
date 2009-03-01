class CreateDownloadedDownloads < ActiveRecord::Migration
  def self.up
    slonik_execute "create table downloaded_downloads (id serial primary key, download_id int not null references downloads match full, created_on timestamp not null default now(), ip inet not null, session_id varchar, referer varchar, user_id int references users);"
  end

  def self.down
    drop_table :downloaded_downloads
  end
end
