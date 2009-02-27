class BazarPortal
  def id
    -2
  end
  
  def default_gmtv_channel_id
    1
  end
  
  def channels
    GmtvChannel.find(:all, :conditions => "gmtv_channels.file is not null AND (gmtv_channels.faction_id IS NULL)", :order => 'gmtv_channels.id ASC', :include => :user)
  end
  
  def name
    'El Bazar de Gamersmafia'
  end
  
  def layout
    'bazar'
  end
  
  def code
    'bazar'
  end
  
  def home
    'bazar'
  end
  
  def skin_id
    nil
  end
  
  def latest_articles
    articles = []
    articles += self.interview.find(:published, :limit => 8, :order => 'created_on DESC') if self.interview
    articles += self.column.find(:published, :limit => 8, :order => 'created_on DESC') if  self.column
    articles += self.tutorial.find(:published, :limit => 8, :order => 'created_on DESC') if self.tutorial
    articles += self.review.find(:published, :limit => 8, :order => 'created_on DESC') if self.review
    
    ordered = {}
    for a in articles
      ordered[a.created_on.to_i] = a
    end
    
    articles = ordered.sort.reverse
    afinal = []
    i = 0
    while i < 8 and i < articles.length do
      afinal << articles[i][1]
      i += 1
    end
    afinal
  end
  
  def skins(user)
    # TODO HACK HACK HACK
    [Skin.find_by_hid('bazar')] + Skin.find(:all)
  end
  
  def skin
    Skin.find_by_hid('bazar') # TODO esto no se usa
  end
  
  def method_missing(method_id, *args)
    if Cms::contents_classes_symbols.include?(method_id) # contents
      if method_id == :poll
        BazarPortalPollProxy
      elsif method_id == :question
        Term.single_toplevel(:slug => 'bazar')
      else
        cls_name = Inflector::camelize(Inflector::singularize(method_id))
        cls = Object.const_get(cls_name)
        if Cms::CONTENTS_WITH_CATEGORIES.include?(cls_name)
          cls = cls.category_class.find_by_code('bazar')
        end
        cls
      end
    elsif /_categories/ =~ method_id.to_s then
      Term.single_toplevel(:slug => 'bazar')
    else
      super
    end
  end
  
  def respond_to?(method_id, include_priv = false)
    if Cms::contents_classes_symbols.include?(method_id) # contents
      true
    elsif /_categories/ =~ method_id.to_s then
      true
    else
      super
    end
  end
  
  def competitions
    Competition
  end
  
  # Devuelve todas las categorías de primer nivel visibles en la clase dada
  def categories(content_class)
    Term.single_toplevel(:slug => 'bazar')
  end
end

class BazarPortalPollProxy
  def self.current
    Term.single_toplevel(:slug => 'bazar').poll.find(:all, :conditions => "starts_on <= now() and ends_on >= now() and state = #{Cms::PUBLISHED}", :order => 'created_on DESC', :limit => 1)
  end
  
  def self.method_missing(method_id, *args)
    GenericContentProxy.new(Poll).send(method_id, *args)
  end
  
  def self.respond_to?(method_id, include_priv = false)
    GenericContentProxy.new(Poll).respond_to?(method_id)
  end
end

class GenericContentProxy
  def initialize(cls)
    @cls = cls
  end
  
  def method_missing(method_id, *args)
    begin
      super
    rescue NoMethodError
      args = _add_restriction_to_cond(*args)
      begin
        @cls.send(method_id, *args)
      rescue ArgumentError
        @cls.send(method_id)
      end
    end
  end
  
  def respond_to?(method_id)
    true
  end
  
  private
  def _add_restriction_to_cond(*args)
    options = args.last.is_a?(Hash) ? args.pop : {} # copypasted de extract_options_from_args!(args)
    new_cond = 'clan_id IS NULL'
    if options[:conditions].kind_of?(Array)
      options[:conditions][0]<< "AND #{new_cond}"
    elsif options[:conditions] then
      options[:conditions]<< " AND #{new_cond}"
    else
      options[:conditions] = new_cond
    end
    args.push(options)
  end
end
