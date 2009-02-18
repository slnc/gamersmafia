class Admin::CompeticionesController < ApplicationController
  before_filter :require_auth_admins
  
  def wmenu_pos
    'arena'
  end
  
  def index
    navpath2<< ['Admin', '/admin']
    @competition_pages, @competitions = paginate :competition, :order => 'state ASC, id ASC', :per_page => 50
  end
  
  def info
    navpath2<< ['Admin', '/admin']
    @competition = Competition.find(params[:id])
    @title = "Editando #{@competition.name}"
  end
  
  def destroy
    @competition = Competition.find(params[:id])
    if @competition.can_be_deleted?
      @competition.destroy
      flash[:notice] = "Competición '#{@competition.name}' borrada correctamente"
    else
      flash[:notice] = "Imposible borrar la competición seleccionada"
    end
    redirect_to '/admin/competiciones'
  end
end
