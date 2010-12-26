module Cuenta::CompeticionesHelper
  def matches_list(matches)
    render :partial => '/cuenta/competiciones/match_list', :locals => {:matches_list => matches}
  end
end
