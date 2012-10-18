# -*- encoding : utf-8 -*-
class CreateSoldUserReferencesNotifications < ActiveRecord::Migration
  def change
    Product.create({
      :name => "Radar",
      :price => 50,
      :description => "<p>Recibe una notificación cada vez que alguien mencione tu nick en un comentario.</p><p>Se puede desactivar en Cuenta &raquo; Notificationes.",
      :cls => "SoldRadar",
    })
  end
end
