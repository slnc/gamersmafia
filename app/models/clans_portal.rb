class ClansPortal < Portal
  belongs_to :clan
  
  def skin
    Skin.find_by_hid('default')
  end
  
  def home
    'clan'
  end
  
  def channels
    # TODO
    GmtvChannel.find(:all, :conditions => "gmtv_channels.file is not null AND (gmtv_channels.faction_id IS NULL)", :order => 'gmtv_channels.id ASC', :include => :user)
  end
  
  def layout
    'clan'
  end
  
  def method_missing(method_id, *args)
    cs_method = Inflector::camelize(Inflector::singularize(method_id))
    if Cms::CLANS_CONTENTS.include?(cs_method)
      cls = Object.const_get(cs_method)
      Object.const_get("#{Inflector::singularize(Inflector::camelize(method_id.to_s.gsub('_categories', '')))}") # necesario para que cree la clase Category
      objs = cls.category_class.find(:all, :conditions => ['id = root_id AND clan_id = ?', clan_id])
      obj = objs[0]
      objs.each { |ob| obj.add_sibling(ob) }
      obj
    elsif /(news|downloads|topics|events|images|polls)_categories/ =~ method_id.to_s then 
      Term.single_toplevel(:clan_id => self.clan_id)
    else
      super
    end
  end
  
  def respond_to?(method_id, include_priv = false)
    cs_method = Inflector::camelize(Inflector::singularize(method_id))
    if Cms::CLANS_CONTENTS.include?(cs_method)
      true
    elsif /(news|downloads|topics|events|images|polls)_categories/ =~ method_id.to_s then 
      true
    else
      super
    end
  end
  
  def categories(content_class)
    content_class.category_class.find(:all, :conditions => "parent_id is null and id = root_id AND clan_id = #{self.clan_id}", :order => 'UPPER(name) ASC')
  end
end
