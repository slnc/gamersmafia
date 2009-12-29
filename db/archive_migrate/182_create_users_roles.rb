class CreateUsersRoles < ActiveRecord::Migration
  def self.up
    slonik_execute "create table users_roles (id serial primary key, user_id int not null references users match full, role varchar not null, role_data varchar);"
    slonik_execute "create unique index users_roles_uniq on users_roles(user_id, role, role_data);"
    slonik_execute "create index users_roles_user_id on users_roles(user_id);"
    slonik_execute "create index users_roles_role on users_roles(role);"
    slonik_execute "create index users_roles_role_role_data on users_roles(role, role_data);"
    slonik_execute "alter table ads_slots add column advertiser_id int references advertisers match full;"
    slonik_execute "alter table ads_slots add column image_dimensions varchar;"
    execute "update ads_slots_instances set deleted='t' where ads_slot_id in (11, 10, 9, 8, 7, 6, 18, 17, 16,15 ,14, 13);"
    execute "update ads_slots set image_dimensions = '120x400' WHERE id = 1;"
    execute "update ads_slots set image_dimensions = '234x60' WHERE id = 3;"
    execute "update ads_slots set image_dimensions = '468x60' WHERE id = 5;"
  end

  def self.down
    drop_table :users_roles
  end
end
