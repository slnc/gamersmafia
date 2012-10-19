class NotificationsTypeId < ActiveRecord::Migration
  def up
    execute "alter table notifications add column type_id int;"
    execute "update notifications set type_id = 0;"
    execute "alter table notifications alter column type_id set not null;"
    execute "alter table notifications add column data varchar;"
  end

  def down
  end
end
