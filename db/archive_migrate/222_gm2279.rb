class Gm2279 < ActiveRecord::Migration
  def self.up
    babescat = ImagesCategory.find_by_code('babes')
    
    User.db_query("SELECT * FROM babes").each do |dbr|
      if Potd.find(:first, :conditions => ["images_category_id = ? AND date = ?", babescat.id, dbr['date']])
        puts "skipping existing babe for " << dbr['date']
        next
      end
      Potd.create(:images_category_id => babescat.id, :image_id => dbr['image_id'].to_i, :date => dbr['date'])
    end
    
    dudescat = ImagesCategory.find_by_code('dudes')
    
    User.db_query("SELECT * FROM dudes").each do |dbr|
      if Potd.find(:first, :conditions => ["images_category_id = ? AND date = ?", babescat.id, dbr['date']])
        puts "skipping existing dude for " << dbr['date']
        next
      end
      Potd.create(:images_category_id => babescat.id, :image_id => dbr['image_id'].to_i, :date => dbr['date'])
    end
  end

  def self.down
  end
end
