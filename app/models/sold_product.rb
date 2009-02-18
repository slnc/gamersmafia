class SoldProduct < ActiveRecord::Base
  belongs_to :user
  belongs_to :product
  
  def use(options={})
    if _use(options) 
      self.used = true 
      self.save
    end
  end
end
