# -*- encoding : utf-8 -*-
class FaccionesController < ComunidadController
  helper :miembros
  def index
    list
    render :action => 'list'
  end

  def list
    @title = 'Facciones'
    @navpath = [['Facciones', '/facciones'], ]
  end

  def borrar
    require_skill("Capo")
    @faction = Faction.find(params[:id])
    raise AccessDenied unless @faction.created_on.to_i >= 2.weeks.ago.to_i
    @faction.referenced_thing.destroy
    if @faction.destroy
      flash[:notice] = "Facción <strong>#{@faction.name}</strong> borrada correctamente."
    else
      flash[:error] = "Error al borrar la facción."
    end
    redirect_to "/facciones"
  end
end
