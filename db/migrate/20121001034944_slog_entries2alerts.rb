class SlogEntries2alerts < ActiveRecord::Migration
  def up
    execute "ALTER TABLE slog_entries RENAME TO alerts;"
  end

  def down
  end
end
