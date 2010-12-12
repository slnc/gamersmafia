class RemoveGlobalNotifications < ActiveRecord::Migration
  def self.up
    User.db_query("alter table sent_emails drop column global_notification_id;")
    User.db_query("alter table users drop column send_global_announces;")
    User.db_query("drop table global_notifications;")
  end

  def self.down
  end
end
