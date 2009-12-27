class FixImagesConstraint < ActiveRecord::Migration
  def self.up
     execute 'alter table images drop constraint "images_images_category_id_fkey";'
  end

  def self.down
  end
end
