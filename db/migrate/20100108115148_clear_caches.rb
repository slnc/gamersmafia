class ClearCaches < ActiveRecord::Migration
  def self.up
    CacheObserver.expire_fragment("/*/site/last_commented_objects")
    CacheObserver.expire_fragment("/_users/*/*/layouts/recommendations")
    FactionsPortal.platform.find(:all).each do |fp|
      CacheObserver.expire_fragment("/#{fp.code}/home/*")
    end
    CacheObserver.expire_fragment("/_users/*/*/layouts/recommendations")
  end

  def self.down
  end
end
