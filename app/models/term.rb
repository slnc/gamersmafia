class Term < ActiveRecord::Base
  belongs_to :game
  belongs_to :bazar_district
  belongs_to :platform
  belongs_to :clan
  
  has_many :contents_terms
  has_many :contents, :through => :contents_terms
  
  # before_save :set_slug
  
  
  acts_as_rootable
  acts_as_tree :order => 'name'
  
  has_slug :name
  before_save :check_references_to_ancestors
  before_save :copy_parent_attrs
  
  # VALIDATES siempre los últimos
  validates_format_of :slug, :with => /^[a-z0-9_.-]{0,50}$/
  validates_format_of :name, :with => /^.{1,100}$/
  validates_uniqueness_of :name, :scope => [:game_id, :bazar_district_id, :platform_id, :clan_id, :taxonomy, :parent_id]
  validates_uniqueness_of :slug, :scope => [:game_id, :bazar_district_id, :platform_id, :clan_id, :taxonomy, :parent_id]
  
  def copy_parent_attrs
    return true if self.id == self.root_id
    
    par = self.parent
    self.game_id = par.game_id
    self.bazar_district_id = par.bazar_district_id
    self.platform_id = par.platform_id
    self.clan_id = par.clan_id
    true
  end
  
  def code
    # TODO temp
    slug
  end
  
  def set_slug
    if self.slug.nil? || self.slug.to_s == ''
      self.slug = self.name.bare.downcase
      # TODO esto no comprueba si el slug está repetido
    end
    true
  end
  
  def mirror_category_tree(category, taxonomy)
    # DEPRECATED: Usado para migrar del sistema viejo de categorías al nuevo sistema de taxonomías
    raise "term is not root term" unless self.id == self.root_id && self.parent_id.nil?    
    
    # Cogemos todos los ancestros de la categoría dada y los vamos creando según sea conveniente
    the_parent = self
    taxonomy_name = category.class.name
    anc = category.get_ancestors
    anc.pop # quitamos toplevel
     ([category] + anc).reverse.each do |ancestor|
      newp = the_parent.children.find(:first, :conditions => ['taxonomy = ? AND name = ?', taxonomy_name, ancestor.name])
      if newp.nil?
        newp = the_parent.children.create(:root_id => the_parent.id, :name => ancestor.name, :taxonomy => taxonomy_name)
      end
      the_parent = newp
    end
    the_parent
  end
  
  def link(content)
    raise "TypeError" unless content.class.name == 'Content'
    if self.contents.find(:first, :conditions => ['contents.id = ?', content.id]).nil? # dupcheck
      self.contents_terms.create(:content_id => content.id)
    end
    true
  end
  
  def unlink(content)
    term = self.contents_terms.find(:all, :conditions => ['content_id = ?', content.id])
    if term
      term.destroy
      true
    else
      false
    end
  end
  
  def self.find_taxonomy(id, taxonomy)
    Term.find(:first, :conditions => ['id = ? AND taxonomy = ?', id, taxonomy])
  end
  
  def self.find_taxonomy_by_code(code, taxonomy)
    # Solo para taxonomías toplevel
    Term.find(:first, :conditions => ['id = root_id AND code = ? AND taxonomy = ?', code, taxonomy])
  end
  
  def self.toplevel(options={})
    conditions = 'id = root_id'
    if options[:clan_id]
      conditions << ' AND clan_id '
      conditions << (options[:clan_id].nil? ? 'IS NULL' : " = #{options[:clan_id].to_i}")
    end
    
    if options[:slug]
      conditions << " AND slug = #{User.connection.quote(options[:slug])}"
    end
    
    conditions << " AND game_id = #{options[:game_id].to_i}" if options[:game_id]
    conditions << " AND platform_id = #{options[:platform_id].to_i}" if options[:platform_id]
    conditions << " AND bazar_district_id = #{options[:bazar_district_id].to_i}" if options[:bazar_district_id]
    conditions << " AND clan_id = #{options[:clan_id].to_i}" if options[:clan_id]
    
    Term.find(:all, :conditions => conditions, :order => 'lower(name)')
  end
  
  def self.single_toplevel(opts={})
    self.toplevel(opts)[0]
  end
  
  # Devuelve los ids de los hijos de la categoría actual o de la categoría obj de forma recursiva incluido el id de obj
  def all_children_ids(opts={})
    cats = [self.id]
    conds = []
    conds << opts[:cond] if opts[:cond].to_s != ''
    conds << "taxonomy = #{User.connection.quote(opts[:taxonomy])}" if opts[:taxonomy]
    
    cond = ''
    cond = " AND #{conds.join(' AND ')}" if conds.size > 0
    
    
    if self.id == self.root_id then # shortcut
      db_query("SELECT id FROM terms WHERE root_id = #{self.id} AND id <> #{self.id} #{cond}").each { |dbc| cats<< dbc['id'].to_i }
    else # hay que ir preguntando categoría por categoría
      if conds.size > 0
        self.children.find(:all, :conditions => cond[4..-1]).each { |child| cats.concat(child.all_children_ids(opts)) }
      else
        self.children.find(:all).each { |child| cats.concat(child.all_children_ids(opts)) }
      end
    end
    cats.uniq
  end
  
  # devuelve portales relacionados con el término actual
  def get_related_portals
    portals = [GmPortal.new]
    if self.game_id || self.platform_id
      portals += Portal.find(:all, :conditions => ['id in (SELECT portal_id from factions_portals where faction_id = ?)', Faction.find_by_code(self.slug).id])
    elsif self.bazar_district_id
      portals << BazarDistrictsPortal.find_by_code(self.slug)
    elsif self.clan_id
      portals << ClansPortal.find_by_clan_id(self.clan_id)
    else # PERF devolvemos todos por contents como funthings 
      portals += Portal.find(:all, :conditions => 'type <> \'ClansPortal\'')
    end
    portals
  end
  
  def recalculate_contents_count
    self.update_attributes(:contents_count => ContentsTerm.count(:conditions => "term_id IN (#{self.all_children_ids(self)})"))
  end
  
  def last_published_content(cls_name, opts={})
    # opts: user_id
    conds = []
    conds << "a.user_id = #{opts[:user_id].to_i}" if opts[:user_id]
    cond = ''
    cond = " AND #{conds.join(' AND ')}" if conds.size > 0
    
    cat_ids = self.all_children_ids(:taxonomy => "#{Inflector::pluralize(cls_name)}Category")
    contents = Content.find_by_sql("SELECT a.* FROM contents a JOIN contents_terms b ON a.id = b.content_id WHERE b.term_id IN (#{cat_ids.join(',')}) AND a.state = #{Cms::PUBLISHED} #{cond} ORDER BY a.created_on DESC LIMIT 1")
    contents.size > 0 ? contents[0] : nil 
  end
  
  def contents_count(cls_name, opts)
    raise "TODO"
  end
  
  
  def reset_contents_urls
    # TODO PERF más inteligencia
    self.find(:all).each do |rc|
      uniq = rc.unique_content
      User.db_query("UPDATE contents SET url = NULL, portal_id = NULL WHERE id = #{uniq.id}")
      uniq.reload
      ApplicationController.gmurl(uniq)
      # self.children.each { |child| child.reset_contents}
    end
  end
  
  # Busca contenidos asociados a este término o a uno de sus hijos
  def find(*args)
    args = _add_cats_ids_cond(*args)
    self.contents.find(*args).collect { |cont| cont.real_content }
    # self.class.items_class.send(:find, *args)
  end
  
  def method_missing(method_id, *args)
    begin
      super
    rescue NoMethodError
      if Cms::CONTENTS_WITH_CATEGORIES.include?(Inflector::camelize(method_id.to_s))
        TermContentProxy.new(Inflector::camelize(method_id.to_s), self)
      else
        raise "No se que hacer con metodo #{method_id}"
        #args = _add_cats_ids_cond(*args)
        #begin
        #  self.class.items_class.send(method_id, *args)
        #rescue ArgumentError
        #  self.class.items_class.send(method_id)
        #end
      end
    end
  end
  
  def respond_to?(method_id, include_priv = false)
    self.class.items_class.respond_to?(method_id) || super
  end
  
  # Cuenta imágenes asociadas a esta categoría o a una de sus hijas
  # TODO se puede optimizar usando caches en categorías para images
  def count(*args)
    args = _add_cats_ids_cond(*args)
    self.contents.count(*args)
  end
  
  
  # acepta keys: treemode (true: incluye categorías de hijos)
  def _add_cats_ids_cond(*args)
    options = {:treemode => true}.merge(args.last.is_a?(Hash) ? args.pop : {}) # copypasted de extract_options_from_args!(args)
    @siblings ||= []
    if options[:treemode]
      @_cache_cats_ids ||= (self.all_children_ids + [self.id])
      @siblings.each { |s| @_cache_cats_ids += s.all_children_ids }
      # options[:conditions] = (options[:conditions]) ? ' AND ' : ''
      
      new_cond = "term_id IN (#{@_cache_cats_ids.join(',')})"
    else
      new_cond = "term_id IN (#{([self.id] + @siblings.collect { |s| s.id }).join(',')})"
    end
    
    if options[:content_type]
      new_cond << " AND contents.content_type_id = #{ContentType.find_by_name(options[:content_type]).id}"
    end
    
    if options[:content_type_id]
      new_cond << " AND contents.content_type_id = #{options[:content_type_id]}"
      #options[:include] ||= []
      #options[:include] << :contents
    end
    
    
    options.delete :treemode
    options.delete :content_type
    options.delete :content_type_id
    
    if options[:conditions].kind_of?(Array)
      options[:conditions][0]<< "AND #{new_cond}"
    elsif options[:conditions] then
      options[:conditions]<< " AND #{new_cond}"
    else
      options[:conditions] = new_cond
    end
    
    agfirst = args.first
    if agfirst.is_a?(Symbol) && [:drafts, :published, :deleted, :pending].include?(agfirst) then
      options = args.last.is_a?(Hash) ? args.pop : {} # copypasted de extract_options_from_args!(args)
      new_cond = "contents.state = #{Cms.const_get(agfirst.to_s.upcase)}"
      
      if options[:conditions].kind_of?(Array)
        options[:conditions][0]<< " AND #{new_cond} "
      elsif options[:conditions].to_s != '' then
        options[:conditions]<< " AND #{new_cond} "
      else
        options[:conditions] = new_cond
      end
      
      options[:order] = "contents.created_on DESC" unless options[:order]
      args[0] = :all
      args.push(options)
    end
    
    args.push(options)
  end
  
  # devuelve el ultimo Content actualizado
  def get_last_updated_item
    if self.last_updated_item_id.nil? then
      cat_ids = self.all_children_ids
      obj = self.contents.find(:first, :order => 'updated_on DESC')
      
      if obj then
        # no usamos save para no tocar updated_on, created_on porque record_timestamps falla
        self.class.db_query("UPDATE terms SET last_updated_item_id = #{obj.id} WHERE id = #{self.id}")
        self.reload
        obj
      end
    else
      self.last_updated_item_id
    end
  end
  
  def get_ancestors 
    # devuelve los ascendientes. en [0] el padre directo y en el último el root
    path = []
    parent = self.parent
    
    while parent do
      path<< parent
      parent = parent.parent
    end
    
    path
  end
  
  def self.find_by_toplevel_group_code(code)
    case code
      when 'gm':
      Term.single_toplevel(:slug => 'gm').children.find(:all, :order => 'lower(name)')
      when 'juegos':
      Term.find(:all, :conditions => 'id = root_id AND game_id IS NOT NULL', :order => 'lower(name)')
      when 'plataformas':
      Term.find(:all, :conditions => 'id = root_id AND platform_id IS NOT NULL', :order => 'lower(name)')
      when 'arena':
      Term.single_toplevel(:slug => 'arena').children.find(:all, :order => 'lower(name)')
      when 'bazar':
      Term.find(:all, :conditions => 'id = root_id AND bazar_district_id IS NOT NULL', :order => 'lower(name)')
    else
      raise "toplevel group code '#{code}' unknown"
    end
  end
  
  private
  def check_references_to_ancestors
    if !self.new_record?
      if slnc_changed?(:parent_id) then
        return false if self.parent_id == self.id # para evitar bucles infinitos
        self.root_id = parent_id.nil? ? self.id : self.class.find(parent_id).root_id
        self.class.find(:all, :conditions => "id IN (#{self.all_children_ids.join(',')})").each do |child|
          next if child.id == self.id
          child.root_id = self.root_id
          child.save
        end
      end
      
      # TODO Rails 2.1 (dirty tracking)
      if slnc_changed?(:root_id) && self.root_id != self.slnc_changed_old_values[:root_id] then # reseteamos la url de todos los contenidos aquí y en categorías inferiores
        GmSys.job("#{self.class.name}.find(#{self.id}).reset_contents_urls")
      end
    end
    true
  end
end

class TermContentProxy
  def initialize(content_name, term)
    @cls_name = content_name
    @term = term
  end
  
  def method_missing(method_id, *args)
    begin
      super
    rescue NoMethodError
      opts = args.last.is_a?(Hash) ? args.pop : {}
      opts[:content_type] = @cls_name        
      args.push(opts)
      args = @term._add_cats_ids_cond(*args)
      begin
        @term.contents.send(method_id, *args).collect { |cont| cont.real_content }
      rescue ArgumentError
        @term.contents.send(method_id)
      end
    end
  end
end