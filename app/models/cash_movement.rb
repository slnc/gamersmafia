class CashMovement < ActiveRecord::Base
  def sender
    Object.const_get(self.object_id_from_class).find_by_id(self.object_id_from) unless self.object_id_from.nil?
  end

  def receiver
    Object.const_get(self.object_id_to_class).find_by_id(self.object_id_to) unless self.object_id_to.nil?
  end
  
  def to_s
    s = self.sender
    s = '(Banco)' unless s
    r = self.sender
    r = '(Banco)' unless r
    
    "transferencia de #{self.ammount} de '#{s}' a '#{r}'"
  end
end
