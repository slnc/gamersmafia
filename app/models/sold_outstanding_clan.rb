# -*- encoding : utf-8 -*-
class SoldOutstandingClan < SoldProduct
  # options debe tener portal_id y clan_id
  def _use(options)
    oe = OutstandingEntity.factory(
        options[:portal_id],
        'OutstandingClan',
        options[:clan_id],
        'Soborno a las altas esferas',
    )
    true
  end
end
