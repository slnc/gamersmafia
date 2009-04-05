class Gm2505 < ActiveRecord::Migration
  def self.up
    CacheObserver.expire_fragment "/common/foros/_forums_list/*"
  end

  def self.down
  end
end
