class Admin::CompeticionesController < ApplicationController
  before_filter :require_auth_admins
  
  def wmenu_pos
    'arena'
  end
  
  def index
    navpath2<< ['Admin', '/admin']
    @competitions = Competition.paginate(:page => params[:page], :per_page => 50, :order => 'state ASC, id ASC')
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
