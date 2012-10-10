class AddSenderUserIdToNotifications < ActiveRecord::Migration
  def change
    execute "alter table notifications add column sender_user_id int not null references users match full"
  end
end
