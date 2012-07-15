# -*- encoding : utf-8 -*-
class Advertiser < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :due_on_day # primer día del mes que no está pagado. Los informes se enviarán a las 00:05 de este día del mes cada mes
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[A-Za-z]{2,})$/
  has_many :ads

  has_users_role 'Advertiser'
end
