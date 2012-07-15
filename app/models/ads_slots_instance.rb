# -*- encoding : utf-8 -*-
class AdsSlotsInstance < ActiveRecord::Base
  belongs_to :ads_slot
  belongs_to :ad

  validates_uniqueness_of :ad_id, :scope => :ads_slot_id

  def mark_as_deleted
    self.deleted = true
    self.save
  end
end
