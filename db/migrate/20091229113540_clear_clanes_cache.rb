class ClearClanesCache < ActiveRecord::Migration
  def self.up
    CacheObserver.expire_fragment("/common/clanes/*")
  end

  def self.down
  end
end
