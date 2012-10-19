class TypeIdNotifications < ActiveRecord::Migration
  def up
    execute "create index notifications_type_id on notifications(user_id, type_id);"
  end

  def down
  end
end
