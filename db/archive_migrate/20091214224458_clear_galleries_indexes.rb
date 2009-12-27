class ClearGalleriesIndexes < ActiveRecord::Migration
  def self.up
    Cache.expire_fragment("/common/imagenes/gallery/*")
  end

  def self.down
  end
end
