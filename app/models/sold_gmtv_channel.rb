# -*- encoding : utf-8 -*-
class SoldGmtvChannel < SoldProduct
  def _use(options)
    GmtvChannel.create({:user_id => self.user_id})
    true
  end
end
