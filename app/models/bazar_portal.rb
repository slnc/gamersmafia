# -*- encoding : utf-8 -*-
class BazarPortal
  def id
    -2
  end

  def default_gmtv_channel_id
    1
  end

  def small_header
	  nil
  end

  def channels
    GmtvChannel.find(:all, :conditions => "gmtv_channels.file is not null AND (gmtv_channels.faction_id IS NULL)", :order => 'gmtv_channels.id ASC', :include => :user)
  end

  def name
    'El Bazar de Gamersmafia'
  end

  def layout
    'default'
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

  def terms_ids(taxonomy=nil)
    Term.top_level.find_by_slug('bazar').all_children_ids(:taxonomy => taxonomy)
  end

  def latest_articles
    articles = []
    articles += Inteview.in_portal(self).published.find(:all, :limit => 8, :order => 'created_on DESC') if self.interview
    articles += Column.in_portal(self).published.find(:all, :limit => 8, :order => 'created_on DESC') if  self.column
    articles += Tutorial.in_portal(self).published.find(:all, :limit => 8, :order => 'created_on DESC') if self.tutorial
    articles += Review.in_portal(self).published.find(:all, :limit => 8, :order => 'created_on DESC') if self.review

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
    Skin.find_by_hid('default')
  end

  def method_missing(method_id, *args)
    if Cms::contents_classes_symbols.include?(method_id) # contents
      if method_id == :poll
        BazarPortalPollProxy
      elsif method_id == :question
        Term.single_toplevel(:slug => 'bazar')
      else
        Term.single_toplevel(:slug => 'bazar')
      end
    elsif /_categories/ =~ method_id.to_s then
      Term.toplevel(:slug => 'bazar')
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
    Term.toplevel(:slug => 'bazar')
  end
end

class BazarPortalPollProxy
  def self.current
    Term.single_toplevel(:slug => 'bazar').poll.published.find(:all, :conditions => "starts_on <= now() and ends_on >= now()", :order => 'created_on DESC', :limit => 1)
  end

  def self.method_missing(method_id, *args)
    Term.single_toplevel(:slug => 'bazar').poll.send(method_id, *args)
  end

  def self.respond_to?(method_id, include_priv = false)
    GenericContentProxy.new(Poll).respond_to?(method_id)
  end
end
