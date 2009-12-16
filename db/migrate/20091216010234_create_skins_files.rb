class CreateSkinsFiles < ActiveRecord::Migration
  def self.up
    slonik_execute "create table skins_files (id serial primary key not null unique, skin_id int not null references skins match full, file varchar not null);"
  end

  def self.down
    drop_table :skins_files
  end
end
