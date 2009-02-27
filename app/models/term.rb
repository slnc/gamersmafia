class Term < ActiveRecord::Base
  belongs_to :game
  belongs_to :bazar_district
  belongs_to :platform
  belongs_to :clan
  
  has_many :contents_terms
  has_many :contents, :through => :contents_terms
  
  before_save :set_slug
  before_save :copy_parent_attrs
  
  acts_as_rootable
  acts_as_tree :order => 'name'
  
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
        # puts "creating ancestor: #{ancestor.name} #{taxonomy_name}"
        newp = the_parent.children.create(:root_id => the_parent.id, :name => ancestor.name, :taxonomy => taxonomy_name)
        p newp if newp.new_record?
        puts newp.errors.full_messages_html if newp.new_record?
        # newp.save
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
      self.children.find(:all, :conditions => (cond.length > 0 ? cond[4..-1] : cond)).each { |child| cats.concat(child.all_children_ids(opts)) }
    end
    
    cats.uniq
  end
  
  def recalculate_count
    self.update_attributes(:count => ContentsTerm.count(:conditions => "term_id IN (#{self.all_children_ids(self)})"))
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
end
