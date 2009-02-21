class Clearblogentrieshomecache < ActiveRecord::Migration
  def self.up
     CacheObserver.expire_fragment("/common/home/index/blogentries")
  end

  def self.down
  end
end
