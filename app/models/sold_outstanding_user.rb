# -*- encoding : utf-8 -*-
class SoldOutstandingUser < SoldProduct
  def _use(options)
    oe = OutstandingEntity.factory(
        'OutstandingUser',
        user_id,
        'Soborno a las altas esferas')
    true
  end
end
