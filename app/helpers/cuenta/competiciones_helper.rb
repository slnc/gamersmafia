module Cuenta::CompeticionesHelper
  def submenu
    'MisCompeticiones'
  end
  
  def submenu_items
    l = []
    if competition && (!competition.new_record?) then
      if competition.user_is_admin(@user.id) then # TODO cache this somewhere?
        l<< ['General', '/cuenta/competiciones']
        l<< ['Configuración', '/cuenta/competiciones/configuracion']
        l<< ['Avanzada', '/cuenta/competiciones/avanzada'] if @competition.has_advanced?
        l<< ['Partidas', '/cuenta/competiciones/partidas']
        l<< ['Participantes', '/cuenta/competiciones/participantes']
        l<< ['Admins y supervisores', '/cuenta/competiciones/admins']
        l<< ['Sponsors', '/cuenta/competiciones/sponsors'] if @competition.pro?
      end
      
      if competition.user_is_participant(@user.id) then # TODO con clanes rulará?
        l<< ['Mis partidas', '/cuenta/competiciones/mis_partidas']
      end
      
      l<< ['Todas mis partidas pendientes', '/cuenta/competiciones/warning_list'] if @user.enable_competition_indicator
    end
    l<< ['&raquo; Cambiar de competición', '/cuenta/competiciones/cambiar']
  end
  
  def matches_list(matches)
    render :partial => '/cuenta/competiciones/match_list', :locals => {:matches_list => matches}
  end
end
