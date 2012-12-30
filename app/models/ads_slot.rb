# -*- encoding : utf-8 -*-
class AdsSlot < ActiveRecord::Base
  VALID_LOCATIONS = %w(
      bottom
      download-page
      download-page-nls
      download-page-second
      sideleft
      sideleft-epsilondecreasing
      sideleft-epsilonfirst
      sideleft-epsilongreedy
      sideleft-leasttaken
      sideleft-poker
      sideleft-softmax
      sideright
      sideright-epsilondecreasing
      sideright-epsilonfirst
      sideright-epsilongreedy
      sideright-leasttaken
      sideright-poker
      sideright-random
      sideright-softmax
  )

  has_many :ads_slots_instances
  has_many :ads, :through => :ads_slots_instances
  after_save :update_global_vars
  before_save :check_image_dimensions
  before_save :check_location
  before_save :set_position
  validates_presence_of :behaviour_class

  def update_global_vars
    GlobalVars.update_var("ads_slots_updated_on", "now()")
  end

  def behaviour
    Ads::SlotsBehaviours.const_get(self.behaviour_class)
  end

  def get_ad(game_id)
    # TODO random por ahora
    self.behaviour.new(self).get_ad(game_id)
  end

  def populate_copy(basep)
    final_opts = {
        :location => self.location,
        :behaviour_class => self.behaviour_class,
        :position => User.db_query(
            "SELECT max(position) + 1 as max
             FROM ads_slots
             WHERE location = '#{self.location}'")[0]['max'].to_i,
    }
    AdsSlot.new(basep.merge(final_opts))
  end

  def update_slots_instances(new_ads_ids)
    # primero chequeamos los viejos que tuviera y si no están en el array los
    # marcamos como borrados
    parsed_ads_ids = []

    self.ads_slots_instances.find(
        :all, :conditions => 'deleted is false').each do |asi|
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
      self.position = AdsSlot.find(
          :first,
          :conditions => ['location = ?', self.location],
          :order => 'position DESC').position + 1
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
