class RemoveSlogVisits < ActiveRecord::Migration
  def up
    execute "drop table slog_visits;"
  end

  def down
  end
end
