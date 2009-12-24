class ClearAllCaches < ActiveRecord::Migration
  def self.up
    CacheObserver.expire_fragment("*")
  end

  def self.down
  end
end
