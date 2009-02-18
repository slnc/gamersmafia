class InformacionController < ApplicationController
  def wmenu_pos
    case @portal.class.name
      when 'BazarPortal':
        'bazar'
      when 'FactionsPortal':
        'facciones'
      when 'BazarDistrictPortal':
        'bazar'
    else
      nil
    end
  end
end
