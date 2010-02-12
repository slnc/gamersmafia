class AchmedObserver < ActiveRecord::Observer
  observe CashMovement
  CASH_MOVEMENT_SUSPICIOUSNESS_THRESHOLD = 5000
  
  def after_create(object)
    case object.class.name
      when 'CashMovement' then
        if object.ammount >= CASH_MOVEMENT_SUSPICIOUSNESS_THRESHOLD
          SlogEntry.create(:type_id => SlogEntry::TYPES[:security], :headline => object.to_s)
        end
    end
  end
end