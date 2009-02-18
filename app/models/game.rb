load RAILS_ROOT + '/Rakefile'

class Game < ActiveRecord::Base
  has_many :games_maps, :dependent => :destroy
  has_many :games_modes, :dependent => :destroy
  has_many :games_versions, :dependent => :destroy
  has_many :users_guids, :dependent => :destroy
  has_many :competitions, :dependent => :destroy
  
  after_create :create_contents_categories
  after_save :update_faction_code
  before_save :check_code_doesnt_belong_to_portal
  
  validates_format_of :code, :with => /^[a-z0-9]{1,6}$/
  validates_format_of :name, :with => /^[a-z0-9:[:space:]]{1,36}$/i
  validates_uniqueness_of :code
  validates_uniqueness_of :name
  
  observe_attr :code
  
  ENTITY_USER = 0
  ENTITY_CLAN = 1
  
  def faction
    Faction.find_by_code(self.code)
  end
  
  def update_faction_code
    # self.class.db_query("update factions set code = (SELECT code from games where games.name = factions.name) WHERE name = '#{self.name.gsub(/'/, '\\\\\'')}'")
  end
  
  def valid_guid?(guid)
    raise 'non-GUID game' unless has_guids
    guid =~ Regexp.compile(self.guid_format)
  end
  
  def create_contents_categories
    content_types = Cms.categories_classes + [TopicsCategory]
    
    # crea las categorías raíz y general para cada contenido
    for ctype in content_types
      new_category = ctype.new({:name => self.name, :code => self.code})
      new_category.save
      raise ActiveRecord::RecordNotFound unless new_category
      new_category = ctype.find(:first, :conditions => ['name = ? and code = ?', self.name, self.code])
    end
    
    
    # crea los foros iniciales para dicho juego
    cforum = TopicsCategory.find(:first, :conditions => ['id = root_id and code = ? and name = ?', self.code, self.name])
    for defname in ['General', 'Ayuda']
      new_forum = cforum.children.create({:name => defname})
    end
    
    # creamos galería inicial
    cgal = ImagesCategory.find(:first, :conditions => ['id = root_id and code = ? and name = ?', self.code, self.name])
    ['General'].each { |defname| cgal.children.create({:name => defname}) }
    
    if not Faction.find_by_name(self.name) then
      f = Faction.new({:name => self.name, :code => self.code})
      f.save
    end
    
    p = Portal.create({:name => self.name, :code => self.code})
    p.factions<< f
  end
  
  after_save :update_img_file
  after_save :update_code_in_other_places_if_changed
  
  def file=(incoming_file)
    
    @temp_file = incoming_file
    @filename = incoming_file.original_filename if incoming_file.to_s != ''
    @content_type = incoming_file.content_type if incoming_file.to_s != ''
  end
  
  def portals
    [GmPortal.new] + FactionsPortal.find_by_sql("select * from portals where id in (select portal_id from factions_portals a join factions b on a.faction_id = b.id and b.code = '#{self.code}')")
  end
  
  def update_img_file
    if @temp_file and @filename != ''
      File.open("#{RAILS_ROOT}/public/storage/games/#{self.code}.gif", "wb+") do |f| 
        f.write(@temp_file.read)
      end
      @temp_file = nil
      Bj.submit 'rake gm:update_default_skin_styles', :tag => 'rake gm:update_default_skin_styles'
    end
  end
  
  # TODO tb a plataformas
  def update_code_in_other_places_if_changed
    if slnc_changed?(:code)
      return if slnc_changed_old_values[:code].nil?
      f = Faction.find_by_code(slnc_changed_old_values[:code].strip)
      
      f.code = self.code
      f.save
      Cms::CONTENTS_WITH_CATEGORIES.each do |content_name|
        root_cat = Object.const_get(content_name).category_class.find(:first, :conditions =>['code = ? and id = root_id', slnc_changed_old_values[:code]])
        root_cat.code = self.code
        root_cat.save
      end
    end
    true
  end
  
  def check_code_doesnt_belong_to_portal
    # TODO dup en Platform.rb
    if self.id
      # TODO Temp Portal.count(:conditions => ["code = ? AND id <> ?", self.code, self.id]) == 0 && !Portal::UNALLOWED_CODES.include?(code)
      true
    else
      Portal.find_by_code(self.code).nil? && !Portal::UNALLOWED_CODES.include?(code)
    end
  end
end
