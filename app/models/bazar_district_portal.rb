class BazarDistrictPortal < Portal
  
  
  def channels  
    GmtvChannel.find(:all, :conditions => "gmtv_channels.file is not null AND (gmtv_channels.faction_id IS NULL)", :order => 'gmtv_channels.id ASC', :include => :user)
  end  
  
  
  def layout
    'bazar'
  end
  
  def home
    'distrito'
  end
  
  # Devuelve todas las categorías de primer nivel visibles en la clase dada
  def categories(content_class)
    content_class.category_class.toplevel(:conditions => "code = \'#{self.code}\'")
  end
  
  # devuelve array de ints con las ids de las categorías visibles del tipo dado
  def get_categories(cls)
    # buscamos los nombres de todas las categorías de los juegos que tenemos
    # asociados
    
    cats = cls.find(:all, :conditions => ["root_id = (SELECT id FROM #{Inflector::tableize(cls.name)} where root_id = id and code = ?)", self.code]).collect { |c| c.id }
    cats << [0] # just in case
    cats
  end
  
  def topics_categories
    TopicsCategory.find(:all, :conditions => "parent_id is null and root_id in (#{get_categories(TopicsCategory).join(',')})", :order => 'UPPER(name) ASC')
  end
  
  def method_missing(method_id, *args)
    if method_id == :poll
      BazarDistrictPortalPollProxy.new(self)
    elsif Cms::contents_classes_symbols.include?(method_id) # contents      
      obj = Object.const_get(Inflector::camelize(Inflector::singularize(method_id)))
      if obj.respond_to?(:is_categorizable?)
        obj = obj.category_class.find_by_code(self.code)
        obj
      end
      obj
    elsif /(news|downloads|topics|events|tutorials|polls|images|questions)_categories/ =~ method_id.to_s then
      # Devolvemos categorías de primer nivel de esta facción
      # it must have at least one
      cls = Object.const_get("#{Inflector::singularize(Inflector::camelize(method_id))}")
      cls.find(:all, :conditions => ["parent_id is null and id = root_id AND code = ?", self.code], :order => 'UPPER(name) ASC')
    else
      super
    end
  end
  
  def respond_to?(method_id, *args)
    if Cms::contents_classes_symbols.include?(method_id) # contents
      true
    elsif /(news|downloads|topics|events|tutorials|polls|images|questions)_categories/ =~ method_id.to_s then
      true
    else
      super
    end
  end
end

class BazarDistrictPortalPollProxy
  def initialize(portal)
    @portal = portal
  end
  
  def current
    Poll.find(:published, :conditions => "polls_category_id IN (#{@portal.get_categories(Poll.category_class).join(',')}) and starts_on <= now() and ends_on >= now()", :order => 'created_on DESC', :limit => 1)
  end
  
  def respond_to?(method_id, include_priv = false)
    true
  end
  
  def respond_to?(method_id, include_priv = false)
    true
  end
  
  def method_missing(method_id, *args)
    obj = Poll
    obj = obj.category_class.find_by_code(@portal.code)    
    obj.send(method_id, *args)
  end
end