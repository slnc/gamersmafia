class Admin::BazarDistrictsController < ApplicationController
  require_admin_permission :bazar_manager
  
  def index
    
  end
  
  def create
    bd = BazarDistrict.new(params[:bazar_district])
    save_or_error(bd, "/admin/bazar_districts", :index)
  end
  
  def edit
    @bd = BazarDistrict.find(params[:id])
    @title = "Editar distrito de bazar #{@bd.name}"
  end
  
  def update
    @bd = BazarDistrict.find(params[:id])
    @bd.update_attributes(params[:bd])
    
    if params[:don] != ''
      newdon = User.find_by_login(params[:don])
      if newdon.nil?
        flash[:error] = "No se ha encontrado al usuario <strong>#{params[:don]}</strong>"
      end
    else
      newdon = nil
    end
    
    if params[:mano_derecha] != ''
      newmano_derecha = User.find_by_login(params[:mano_derecha])
      if newmano_derecha.nil?
        flash[:error] ||= '<br />'
        flash[:error]<< "No se ha encontrado al usuario <strong>#{params[:don]}</strong>"
      end
    else
      newmano_derecha = nil
    end    
        
    if flash[:error].to_s == ''
      @bd.update_don(newdon)
      @bd.update_mano_derecha(newmano_derecha)
      flash[:notice] = "Datos actualizados correctamente."
    end
    
    redirect_to "/admin/bazar_districts/edit/#{@bd.id}"
  end
end
