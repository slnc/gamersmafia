class FixUsersAportacionesCaches < ActiveRecord::Migration
  def self.up
    CacheObserver.expire_fragment("/_users/*/*/profile/aportaciones")
  end

  def self.down
  end
end
