class Gm2251 < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table slog_entries add column scope int;"
  end

  def self.down
  end
end
