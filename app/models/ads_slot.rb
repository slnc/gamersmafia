class AdsSlot < ActiveRecord::Base
  has_many :ads_slots_instances
  has_many :ads, :through => :ads_slots_instances
  validates_presence_of :behaviour_class
  
  after_save :update_global_vars
  
  
  before_save :check_image_dimensions
  # has_and_belongs_to_many :portals
  
  def link_to_portal(portal)
    # Hay portales con ids negativos, por eso no usamos has_and_belongs_to_many
    if User.db_query("SELECT count(*) FROM ads_slots_portals WHERE ads_slot_id = #{self.id} AND portal_id = #{portal.id}")[0]['count'].to_i > 0
      self.errors.add("La asociación ya existe.")
      false
    else
      User.db_query("INSERT INTO ads_slots_portals(portal_id, ads_slot_id) VALUES(#{portal.id}, #{self.id})")
      true
    end
  end
  
  def unlink_from_portal(portal)
    if User.db_query("SELECT count(*) FROM ads_slots_portals WHERE ads_slot_id = #{self.id} AND portal_id = #{portal.id}")[0]['count'].to_i > 0
      User.db_query("DELETE FROM ads_slots_portals WHERE portal_id = #{portal.id} AND ads_slot_id = #{self.id}")
      true
    else
      self.errors.add("La asociación no existe.")
      false
    end
  end
  
  def update_global_vars
    User.db_query("UPDATE global_vars SET ads_slots_updated_on = now();")
  end
  
  def portals
    User.db_query("SELECT * FROM ads_slots_portals WHERE ads_slot_id = #{self.id}").collect { |dbr| Portal.find_by_id(dbr['portal_id'].to_i)}
  end
  
  VALID_LOCATIONS = %w(bottom sideleft sideright sideright-random sideleft-epsilongreedy sideleft-epsilonfirst sideleft-epsilondecreasing sideleft-leasttaken sideleft-softmax sideleft-poker sideright-epsilongreedy sideright-epsilonfirst sideright-epsilondecreasing sideright-leasttaken sideright-softmax sideright-poker download-page download-page-nls download-page-second)
  before_save :check_location
  before_save :set_position
  
  def behaviour
    Ads::SlotsBehaviours.const_get(self.behaviour_class)
  end
  
  def get_ad(game_id)
    # TODO random por ahora
    self.behaviour.new(self).get_ad(game_id)
  end
  
  def populate_copy(basep)
    AdsSlot.new(basep.merge({:location => self.location, 
                             :behaviour_class => self.behaviour_class, 
                             :position => User.db_query("SELECT max(position) + 1 as max FROM ads_slots WHERE location = '#{self.location}'")[0]['max'].to_i}))
  end
  
  def update_slots_instances(new_ads_ids)
    # primero chequeamos los viejos que tuviera y si no están en el array los marcamos como borrados
    parsed_ads_ids = []
    
    self.ads_slots_instances.find(:all, :conditions => 'deleted is false').each do |asi|
      if !new_ads_ids.include?(asi.ad_id)
        asi.mark_as_deleted
      end
      parsed_ads_ids<< asi.ad_id
    end
    
     (new_ads_ids - parsed_ads_ids).each do |ad_id|
      prev = self.ads_slots_instances.find_by_ad_id(ad_id)
      if prev && prev.deleted
        prev.deleted = false
        prev.save
      else
        self.ads_slots_instances.create(:ad_id => ad_id)  
      end
    end
  end
  
  def pageviews(what, days)
    
  end
  
  def clicks(what, days)
    
  end
  
  private
  def check_location
    location && VALID_LOCATIONS.include?(location)
  end
  
  def set_position
    if self.position.nil?
      self.position = AdsSlot.find(:first, :conditions => ['location = ?', self.location], :order => 'position DESC').position + 1 
    end
  end
  
  def check_image_dimensions
    if !(self.image_dimensions.to_s == '' || /([0-9]+)x([0-9]+)/ =~ self.image_dimensions)
      self.errors.add('image_dimensions', 'Dimensiones de la imagen incorrectas')
      false
    else
      true
    end
  end
end
