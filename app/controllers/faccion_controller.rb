# -*- encoding : utf-8 -*-
class FaccionController < ApplicationController
  before_filter do |c|
    c.faction = Faction.find_by_code(c.portal.code)
    if c.faction.nil?
      raise ActiveRecord::RecordNotFound
      Rails.logger.error("Cannot find faction for portal #{c.portal.code}")
    end
  end
  attr_accessor :faction

  def submenu
    'Facción'
  end

  def submenu_items
    [['Información', '/faccion'],
    ['Miembros', '/faccion/miembros'],
    ['Clanes', '/faccion/clanes'],
    ['Staff', '/faccion/staff']]
  end

  def index
  end

  def miembros
  end

  def clanes
  end

  def staff
  end
end
