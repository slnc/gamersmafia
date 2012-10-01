class PendingAlerts < ActiveRecord::Migration
  def up
    execute "alter table users rename pending_slog to pending_alerts;"
  end

  def down
  end
end
