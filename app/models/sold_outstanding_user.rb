# -*- encoding : utf-8 -*-
class SoldOutstandingUser < SoldProduct
  # options debe tener portal_id
  def _use(options)
    oe = OutstandingEntity.factory(
        options[:portal_id],
        'OutstandingUser',
        user_id,
        'Soborno a las altas esferas')
    true
  end
end
