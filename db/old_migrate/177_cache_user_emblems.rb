class CacheUserEmblems < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table users add column emblems_mask varchar;"
  end

  def self.down
  end
end
