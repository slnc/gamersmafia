class Gm1972 < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table comments add column netiquette_violation bool;"
  end

  def self.down
  end
end
