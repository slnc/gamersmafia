class AdsSlot < ActiveRecord::Base
  has_many :ads_slots_instances
  has_many :ads, :through => :ads_slots_instances
  validates_presence_of :behaviour_class
  
  after_save :update_global_vars
  
  
  before_save :check_image_dimensions
  # has_and_belongs_to_many :portals
  
  def update_global_vars
    User.db_query("UPDATE global_vars SET ads_slots_updated_on = now();")
  end
  
  def portals
    User.db_query("SELECT * FROM ads_slots_portals WHERE ads_slot_id = #{self.id}").collect { |dbr| Portal.find_by_id(dbr['portal_id'].to_i)}
  end
  
  VALID_LOCATIONS = %w(bottom sideleft sideright sideright-random sideleft-epsilongreedy sideleft-epsilonfirst sideleft-epsilondecreasing sideleft-leasttaken sideleft-softmax sideleft-poker sideright-epsilongreedy sideright-epsilonfirst sideright-epsilondecreasing sideright-leasttaken sideright-softmax sideright-poker download-page download-page-nls)
  before_save :check_location
  before_save :set_position
  
  def behaviour
    Ads::SlotsBehaviours.const_get(self.behaviour_class)
  end
  
  def get_ad(game_id)
    # TODO random por ahora
    self.behaviour.new(self).get_ad(game_id)
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
