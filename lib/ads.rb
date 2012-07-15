# -*- encoding : utf-8 -*-
module Ads
  module SlotsBehaviours
    VALID_BEHAVIOURS = ['Random']

    class AbstractBehaviour
      def initialize(ads_slot)
        @ads_slot = ads_slot
      end

      def get_ad(game_id)
        raise "abstract method"
      end
    end

    class Random < AbstractBehaviour
      def get_ad(game_id)
        @ads_slot.ads_slots_instances.find(:first, :conditions => 'deleted = \'f\'', :order => 'RANDOM()', :include => :ad)
      end
    end
  end
end
