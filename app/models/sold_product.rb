# -*- encoding : utf-8 -*-
class SoldProduct < ActiveRecord::Base
  belongs_to :user
  belongs_to :product

  scope :factions, :conditions => "type = 'SoldFaction'"
  scope :recent, :conditions => 'created_on >= now() - \'3 months\'::interval'

  validates_presence_of :price_paid

  def use(options={})
    if _use(options)
      self.used = true
      self.save
    end
  end
end
