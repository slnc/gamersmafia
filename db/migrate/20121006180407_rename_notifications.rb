class RenameNotifications < ActiveRecord::Migration
  def up
    execute "
        CREATE TABLE notifications (
          id serial primary key not null unique,
          user_id int not null references users on delete cascade,
          created_on timestamp not null default now(),
          description varchar,
          read_on timestamp
        );
        CREATE INDEX notifications_common on notifications(user_id, read_on);

    "

    execute "alter table users add column has_unread_notifications bool not null default false;"
  end

  def down
  end
end
