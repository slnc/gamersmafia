class AddEntityIdToAlert < ActiveRecord::Migration
  def change
    User.db_query("ALTER TABLE slog_entries ADD COLUMN entity_id int")
    User.db_query("ALTER TABLE slog_entries ADD COLUMN data varchar")
  end
end
