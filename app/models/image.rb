# -*- encoding : utf-8 -*-
# ContentAttribute:
# - file_hash_md5 (varchar)
# - file (varchar)
class Image < Content
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

  def to_s
    ("Image: id: #{self.id}")
  end

  def home_image
    raise "not implemented"
    return "/#{self.file}"
  end
end
