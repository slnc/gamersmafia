# -*- encoding : utf-8 -*-
class SoldOutstandingClan < SoldProduct
  # options debe tener portal_id y clan_id
  def _use(options)
    oe = OutstandingEntity.factory(options[:portal_id], 'OutstandingClan', options[:clan_id], 'Soborno a las altas esferas')
    Message.create({:user_id_to => self.user_id, :user_id_from => User.find_by_login('nagato').id, :title => "Fecha de publicación de tu compra de \"Clan Destacado\"", :message => "El producto \"Clan destacado\" que acabas de comprar estará activo durante todo el día #{oe.active_on.strftime('%d de %B de %Y')} en portada de #{oe.portal.name}."})
    true
  end
end
