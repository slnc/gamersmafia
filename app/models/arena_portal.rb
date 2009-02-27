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
        ArenaPortalPollProxy
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
      Term.single_toplevel(:arena)
    else
      super
    end
  end
  
  def competitions
    Competition
  end
  
  # Devuelve todas las categorías de primer nivel visibles en la clase dada
  def categories(content_class)
    Term.toplevel(:slug => 'arena')
  end
end

class ArenaPortalPollProxy
  def self.current
    Term.single_toplevel(:slug => 'arena').poll.find(:all, :conditions => "starts_on <= now() and ends_on >= now() and state = #{Cms::PUBLISHED}", :order => 'created_on DESC', :limit => 1)
  end
  
  def self.method_missing(method_id, *args)
    GenericContentProxy.new(Poll).send(method_id, *args)
  end
  
  def self.respond_to?(method_id)
    GenericContentProxy.new(Poll).respond_to?(method_id)
  end
end