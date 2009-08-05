class Admin::AdsController < AdministrationController
  def index    
  end
  
  def new
    @ad = Ad.new
  end
  
  def create
    @ad = Ad.new(params[:ad])
    if @ad.save
      flash[:notice] = 'Ad creado correctamente.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end
  
  def create_and_associate
    @ad = Ad.new(params[:ad])
    if @ad.save
      flash[:notice] = 'Ad creado correctamente.'
      @ads_slot = AdsSlot.find(params[:ads_slot_id])
      @ads_slot.ads_slots_instances.create(:ad_id => @ad.id)
    end
    redirect_to params[:redirto] ? params[:redirto] : '/admin/ads'
  end
  
  def edit
    @ad = Ad.find(params[:id])
    @title = "Editar ad: #{@ad.name}"
  end
  
  def update
    @ad = Ad.find(params[:id])
    if @ad.update_attributes(params[:ad])
      flash[:notice] = 'Ad actualizado correctamente.'
      redirect_to :action => 'edit', :id => @ad
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    if Ad.find(params[:id]).destroy
      flash[:notice] = "Ad eliminado correctamente."
    else
      flash[:error] = "Error al borrar ad"
    end
    redirect_to :action => 'index'
  end
end
