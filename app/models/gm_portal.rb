class GmPortal

  def layout
    'gm'
  end
  def small_header
	  nil
  end

  def id
    -1
  end

  def default_gmtv_channel_id
    1
  end

  def channels
    GmtvChannel.find(:all, :conditions => "gmtv_channels.file is not null AND (gmtv_channels.faction_id IS NULL)", :order => 'gmtv_channels.id ASC', :include => :user)
  end

  def name
    'Gamersmafia'
  end

  def code
    'gm'
  end

  def home
    'gm'
  end

  def skin_id
    nil
  end

  def skins(user)
    # TODO HACK HACK HACK
    [Skin.find_by_hid('default')] + Skin.find(:all)
  end

  def skin
    Skin.find_by_hid('default')
  end

  def method_missing(method_id, *args)
    if Cms::contents_classes_symbols.include?(method_id) # contents
      if method_id == :poll
        GmPortalPollProxy
      else
        cls_name = ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id))
        cls = Object.const_get(cls_name)

        if Cms::CLANS_CONTENTS.include?(cls_name)  # es una clase cuya tabla tiene clan_id, añadimos constraint
          GenericContentProxy.new(cls, 'gm')
        else
          GenericContentProxy.new(cls, 'gm')
        end
      end
    elsif /_categories/ =~ method_id.to_s then
      Term.toplevel(:clan_id => nil)
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
    Term.toplevel(:slug => 'gm')
  end
end

class GmPortalPollProxy
  def self.current
    Term.single_toplevel(:slug => 'gm').poll.find(:published, :conditions => Poll::CURRENT_SQL, :order => 'polls.created_on DESC', :limit => 1)
  end

  def self.method_missing(method_id, *args)
    Term.single_toplevel(:slug => 'gm').poll.send(method_id, *args)
  end
end
