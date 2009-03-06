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
    end
  end
end
