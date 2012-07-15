# -*- encoding : utf-8 -*-
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
    cs_method = ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s))
    if Cms::CLANS_CONTENTS.include?(cs_method)
      t = Term.single_toplevel(:clan_id => self.clan_id)
    elsif /(news|downloads|topics|events|images|polls)_categories/ =~ method_id.to_s then
      Term.toplevel(:clan_id => self.clan_id)
    else
      super
    end
  end

  def respond_to?(method_id, include_priv = false)
    cs_method = ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s))
    if Cms::CLANS_CONTENTS.include?(cs_method)
      true
    elsif /(news|downloads|topics|events|images|polls)_categories/ =~ method_id.to_s then
      true
    else
      super
    end
  end

  def categories(content_class)
    Term.toplevel(:clan_id => self.clan_id)
  end
end
