class Ad < ActiveRecord::Base
  has_many :ads_slots_instances
  has_many :ads_slots, :through => :ads_slots_instances
  file_column :file
  before_save :check_not_both
  belongs_to :advertiser
  
  def ad_html(ads_slot_instance_id, image_dimensions)
    out = self.file ? "<a class=\"slncadt\" id=\"adsi#{ads_slot_instance_id}#{'--' << @tmpinfo if @tmpinfo}\" target=\"_blank\" href=\"#{self.link_file}\"><img src=\"/cache/thumbnails/f/#{image_dimensions}/#{self.file}\" /></a>" : self.html
    #out << 
  end
  
  def tmpinfo(new_tmpinfo)
    @tmpinfo = new_tmpinfo
  end
  
  def check_not_both
    if (file.to_s == '' && html.to_s != '') || (file.to_s != '' && html.to_s == '')
      true
    else
      self.errors.add('file', 'codigo html incorrecto')
      false
    end
  end
  validates_length_of :name, :minimum => 1, :allow_nil => false
end
