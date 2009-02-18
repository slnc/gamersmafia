class CreateContentsVersions < ActiveRecord::Migration
  def self.up
    slonik_execute "create table contents_versions (id serial primary key, created_on timestamp not null default now(), content_id int not null references contents match full, data text);" 
  end

  def self.down
    drop_table :contents_versions
  end
end
