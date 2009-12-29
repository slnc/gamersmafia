class FixSlogentriesTypes < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table slog_entries alter column type_id type int4;"
  end

  def self.down
  end
end
