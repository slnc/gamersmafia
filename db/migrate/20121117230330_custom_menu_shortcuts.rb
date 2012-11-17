class CustomMenuShortcuts < ActiveRecord::Migration
  def up
    execute "alter table user_interests add column menu_shortcut varchar;"
    execute "update user_interests set menu_shortcut = (SELECT slug FROM terms WHERE id = entity_id);"
    execute "alter table user_interests alter column menu_shortcut set not null;"
  end

  def down
  end
end
