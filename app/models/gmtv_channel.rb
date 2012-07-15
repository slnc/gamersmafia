# -*- encoding : utf-8 -*-
class GmtvChannel < ActiveRecord::Base
  file_column :file
  file_column :screenshot
  belongs_to :faction
  belongs_to :user

  def get_related_portals
    if faction_id
      self.faction.portals
    else # maybe general
      [GmPortal.new, ArenaPortal.new, BazarPortal.new]
    end
  end
end
