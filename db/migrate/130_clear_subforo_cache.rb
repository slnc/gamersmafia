class ClearSubforoCache < ActiveRecord::Migration
  def self.up
    CacheObserver.expire_fragment("common/foros/subforos/*")
  end

  def self.down
  end
end
