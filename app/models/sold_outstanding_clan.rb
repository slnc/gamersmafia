# -*- encoding : utf-8 -*-
class SoldOutstandingClan < SoldProduct
  def _use(options)
    oe = OutstandingEntity.factory(
        'OutstandingClan',
        options[:clan_id],
        'Soborno a las altas esferas',
    )
    true
  end
end
