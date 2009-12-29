class AddPlatformsUsersRel < ActiveRecord::Migration
  def self.up
    slonik_execute "create table platforms_users(id serial primary key not null unique, created_on timestamp, user_id int references users match full on delete cascade, platform_id int references platforms match full on delete cascade);"
    slonik_execute "create unique index platforms_users_platform_id_user_id on platforms_users(user_id, platform_id);"
    slonik_execute "create index platforms_users_user_id on platforms_users(user_id);"
    slonik_execute "create index platforms_users_platform_id on platforms_users(platform_id);"
  end

  def self.down
  end
end
