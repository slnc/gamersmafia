class CreateClansMovements < ActiveRecord::Migration
  def self.up
    slonik_execute "create table clans_movements (id serial primary key not null unique, clan_id int not null references clans match full, user_id int references users match full, direction smallint not null, created_on timestamp not null default now());"
  end

  def self.down
    drop_table :clans_movements
  end
end
