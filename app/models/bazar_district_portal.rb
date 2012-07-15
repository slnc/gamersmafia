# -*- encoding : utf-8 -*-
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

  def bazar_district
    BazarDistrict.find_by_code(self.code)
  end

  # Devuelve todas las categorías de primer nivel visibles en la clase dada
  def categories(content_class)
    Term.toplevel(:slug => self.code)
  end

  def terms_ids(taxonomy=nil)
    terms = Term.top_level.find(:all, :conditions => ["slug = ?", self.code], :order => 'UPPER(name) ASC')
    res = []
    terms.each do |t|
      res += t.all_children_ids(:taxonomy => taxonomy)
    end
    res
  end

  # devuelve array de ints con las ids de las categorías visibles del tipo dado
  def get_categories(cls)
    # buscamos los nombres de todas las categorías de los juegos que tenemos
    # asociados
    Term.single_toplevel(:slug => self.code).all_children_ids
  end

  def method_missing(method_id, *args)
    if method_id == :poll
      BazarDistrictPortalPollProxy.new(self)
    elsif Cms::contents_classes_symbols.include?(method_id) # contents
      obj = Object.const_get(ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s)))
      if obj.respond_to?(:is_categorizable?)
        t = Term.single_toplevel(:slug => self.code)
        t.add_content_type_mask(obj.name)
        obj = t
      end
      obj
    elsif /(news|downloads|topics|events|tutorials|polls|images|questions)_categories/ =~ method_id.to_s then
      # Devolvemos categorías de primer nivel de esta facción
      # it must have at least one
      Term.toplevel(:slug => self.code)
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
    codes = @portal.categories(nil).collect {|pcc| pcc.code}
    codes.collect! {|pcc| "'#{pcc}'" }
    t = Term.find(
      :first,
      :conditions => "id = root_id AND slug IN (#{codes.join(',')})",
      :order => 'UPPER(name) ASC')
    t.poll.find(:published,
                :conditions => Poll::CURRENT_SQL,
                :order => 'created_on DESC',
                :limit => 1)
  end

  def respond_to?(method_id, include_priv = false)
    true
  end

  def respond_to?(method_id, include_priv = false)
    true
  end

  def method_missing(method_id, *args)
    @portal.categories(nil)[0].poll.send(method_id, *args)
  end
end
