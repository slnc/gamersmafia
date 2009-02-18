class Gm1877 < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table global_vars add column pending_contents int not null default 0;"
  end

  def self.down
  end
end
