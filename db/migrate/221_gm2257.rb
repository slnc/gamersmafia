class Gm2257 < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table users add column pending_slog int not null default 0;"
  end

  def self.down
  end
end
