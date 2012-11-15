class MigrateShowInMenu < ActiveRecord::Migration
  def up
    execute "alter table user_interests add column show_in_menu bool not null default 't';"
    execute "create index user_interests_show_in_menu on user_interests(user_id, show_in_menu);"
  end

  def down
  end
end
