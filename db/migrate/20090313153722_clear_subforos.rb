class ClearSubforos < ActiveRecord::Migration
  def self.up
	`rm #{FRAGMENT_CACHE_PATH}/common/foros/subforos/*`
  end

  def self.down
  end
end
