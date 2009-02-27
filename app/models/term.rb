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
end
