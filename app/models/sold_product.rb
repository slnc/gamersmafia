class SoldProduct < ActiveRecord::Base
  belongs_to :user
  belongs_to :product
  
  named_scope :factions, :conditions => 'type = \'SoldFaction\''
  named_scope :recent, :conditions => 'created_on >= now() - \'3 months\'::interval'
  
  def use(options={})
    if _use(options) 
      self.used = true 
      self.save
    end
  end
end
