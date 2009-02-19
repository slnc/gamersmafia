class ArenaPortal
  def id
    -3
  end
  
  def default_gmtv_channel_id
    1
  end
  
  def channels
    GmtvChannel.find(:all, :conditions => "gmtv_channels.file is not null AND (gmtv_channels.faction_id IS NULL)", :order => 'gmtv_channels.id ASC', :include => :user)
  end
  
  def name
    'Gamersmafia Arena'
  end
  
  def layout
    'arena'
  end
  
  def code
    'arena'
  end
  
  def home
    'arena'
  end
  
  def skin_id
    nil
  end
  
  def skins(user)
    # TODO HACK HACK HACK
    [Skin.find_by_hid('arena')] + Skin.find(:all)
  end
  
  def skin
    Skin.find_by_hid('arena') # TODO esto no se usa
  end
  
  def respond_to?(method_id, include_priv = false)
    if Cms::contents_classes_symbols.include?(method_id) # contents
      true
    elsif /_categories/ =~ method_id.to_s then
      # it must have at least one
      true
    else
      super
    end
  end
  
  def method_missing(method_id, *args)
    if Cms::contents_classes_symbols.include?(method_id) # contents
      if method_id == :poll
        GmPortalPollProxy
      else
        cls_name = ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id))
        cls = Object.const_get(cls_name)
        if Cms::CLANS_CONTENTS.include?(cls_name)  # es una clase cuya tabla tiene clan_id, añadimos constraint
          GenericContentProxy.new(cls)
        else
          cls
        end
      end
    elsif /_categories/ =~ method_id.to_s then
      # it must have at least one
      cls_name = ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id))
      single_name = ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s.gsub('_categories', '')))
      cls = Object.const_get(cls_name)
      raise "FUCK"
      cond = Cms::CLANS_CONTENTS.include?(single_name) ? "AND clan_id IS NULL " : ''
      cls.find(:all, :conditions => "parent_id is null and id = root_id AND code = 'arena'", :order => 'UPPER(name) ASC')
    else
      super
    end
  end
  
  def competitions
    Competition
  end
  
  # Devuelve todas las categorías de primer nivel visibles en la clase dada
  def categories(content_class)
    if content_class.name == 'Poll'
      PollsCategory.find(:all, :conditions => 'id = root_id AND code = \'gm\'')
    else
      content_class.category_class.toplevel(:conditions => 'clan_id is null')
    end
  end
  
  def topics_categories
    TopicsCategory.find(:all, :conditions => 'parent_id is null AND clan_id IS NULL and code = \'arena\'')
  end
end

class GmPortalPollProxy
  def self.current
    cat_id = PollsCategory.find(:first, :conditions => ['id = root_id and code = ?', 'gm']).id
    Poll.find(:all, :conditions => "polls_category_id = #{cat_id} and starts_on <= now() and ends_on >= now() and state = #{Cms::PUBLISHED}", :order => 'created_on DESC', :limit => 1)
  end
  
  def self.method_missing(method_id, *args)
    GenericContentProxy.new(Poll).send(method_id, *args)
  end
  
  def self.respond_to?(method_id)
    GenericContentProxy.new(Poll).respond_to?(method_id)
  end
end

class GenericContentProxy
  def initialize(cls)
    @cls = cls
  end
  
  def respond_to?(method_id, include_priv = false)
    true
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
