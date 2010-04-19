class Admin::PortalesController < AdministrationController
  def index
    
  end
  
  def editar
    @theportal = Portal.find(params[:id])
    @title = "Editando portal #{@theportal.name}"
  end
  
  def update
    @theportal = Portal.find(params[:id])
    params[:portal][:skin_id] = params[:theportal][:skin_id]
    @theportal.update_attributes(params[:portal])
    redirect_to "/admin/portales/editar/#{@theportal.id}"
  end
end
