class AchmedObserver < ActiveRecord::Observer
  CASH_MOVEMENT_SUSPICIOUSNESS_THRESHOLD = 5000

  observe CashMovement

  def after_create(object)
    case object.class.name
      when 'CashMovement' then
        if object.ammount >= CASH_MOVEMENT_SUSPICIOUSNESS_THRESHOLD
          SlogEntry.create(:headline => object.to_s,
                           :type_id => SlogEntry::TYPES[:security])
        end
    end
  end
end