class Optimizcratings < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table comments add column cache_rating varchar;"
  end

  def self.down
  end
end
