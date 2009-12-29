class Gmlblabla < ActiveRecord::Migration
  def self.up
    `find #{FRAGMENT_CACHE_PATH}/common/clanes -type f -exec rm {} \\\;`
  end

  def self.down
  end
end
