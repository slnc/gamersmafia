class Image < ActiveRecord::Base
  acts_as_content
  acts_as_categorizable
  
  has_many :potds, :dependent => :destroy
  
  file_column :file
  
  after_save do |m|
    if m.state != Cms::PUBLISHED then
      for obj in Potd.find(:all, :conditions => ['image_id = ?', m.id])
        obj.destroy
        # TODO si ha sido potd deberíamos limpiar las caches :S
      end
    else
      if m.slnc_changed?(:images_category_id) and m.slnc_changed_old_values[:images_category_id] and m.images_category(true).root_id == ImagesCategory.find(:first, :conditions => "id = root_id and code = 'bazar'").id then
        Potd.find(:all, :conditions => ['image_id = ?', m.id]).each { |potd| potd.destroy }
      end
    end
  end
end
