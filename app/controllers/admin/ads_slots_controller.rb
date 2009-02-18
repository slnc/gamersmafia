class Admin::AdsSlotsController < AdministrationController
  def index
    
  end
  
  def new
    @ads_slot = AdsSlot.new
  end
  
  def create
    @ads_slot = AdsSlot.new(params[:ads_slot])
    if @ads_slot.save
      flash[:notice] = 'AdsSlot creado correctamente.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end
  
  def copy
    @ads_slot_orig = AdsSlot.find(params[:id])
    @ads_slot = AdsSlot.new(params[:ads_slot])
    @ads_slot.location = @ads_slot_orig.location
    @ads_slot.behaviour_class = @ads_slot_orig.behaviour_class
    @ads_slot.position = User.db_query("SELECT max(position) + 1 as max FROM ads_slots WHERE location = '#{@ads_slot_orig.location}'")[0]['max'].to_i
    if @ads_slot.save
      params[:ads] = @ads_slot_orig.ads.collect { |ad| ad.id }
      @as = @ads_slot
      _update_slots_instances
      flash[:notice] = 'AdsSlot copiado correctamente.'
      redirect_to :action => 'index'
    else
      flash[:error] = "Error al crear el AdsSlot: #{@ads_slot.errors.full_messages_html}"
      render :action => 'new'
    end
  end
  
  def edit
    @ads_slot = AdsSlot.find(params[:id])
    @title = "Editar ad: #{@ads_slot.name}"
  end
  
  def update
    @ads_slot = AdsSlot.find(params[:id])
    if @ads_slot.update_attributes(params[:ads_slot])
      flash[:notice] = 'AdsSlot actualizado correctamente.'
      redirect_to :action => 'edit', :id => @ads_slot
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    if AdsSlot.find(params[:id]).destroy
      flash[:notice] = "AdsSlot eliminado correctamente."
    else
      flash[:error] = "Error al borrar ads slot"
    end
    redirect_to :action => 'index'
  end
  
  def _update_slots_instances
    
    params[:ads] ||= []
    # primero chequeamos los viejos que tuviera y si no están en el array los marcamos como borrados
    parsed_ads_ids = []
    @as.ads_slots_instances.find(:all, :conditions => 'deleted is false').each do |asi|
      if !params[:ads].include?(asi.ad_id.to_s)
        asi.mark_as_deleted
      end
      parsed_ads_ids<< asi.ad_id.to_s
    end
    
     (params[:ads] - parsed_ads_ids).each do |ad_id|
      prev = @as.ads_slots_instances.find_by_ad_id(ad_id)
      if prev && prev.deleted
        prev.deleted = false
        prev.save
      else
        @as.ads_slots_instances.create(:ad_id => ad_id)  
      end
    end
  end
  
  def update_slots_instances
    @as = AdsSlot.find(params[:id])
    _update_slots_instances
    redirect_to "/admin/ads_slots/edit/#{@as.id}"
  end
  
  def add_to_portal
    as = AdsSlot.find(params[:id])
    portal = Portal.find_by_id(params[:portal_id])
    raise ActiveRecord::RecordNotFound unless portal
    if User.db_query("SELECT count(*) FROM ads_slots_portals WHERE ads_slot_id = #{as.id} AND portal_id = #{portal.id}")[0]['count'].to_i > 0
      flash[:error] = "La asociación ya existe."
    else
      User.db_query("INSERT INTO ads_slots_portals(portal_id, ads_slot_id) VALUES(#{portal.id}, #{as.id})")
      flash[:notice] = "Asociación creada correctamente."
    end
    
    redirect_to "/admin/ads_slots/edit/#{as.id}"
  end
  
  def remove_from_portal
    as = AdsSlot.find(params[:id])
    portal = Portal.find_by_id(params[:portal_id])
    raise ActiveRecord::RecordNotFound unless portal
    if User.db_query("SELECT count(*) FROM ads_slots_portals WHERE ads_slot_id = #{as.id} AND portal_id = #{portal.id}")[0]['count'].to_i > 0
      User.db_query("DELETE FROM ads_slots_portals WHERE portal_id = #{portal.id} AND ads_slot_id = #{as.id}")
      # as.portals.delete(Portal.find_by_id(params[:portal_id]))
      flash[:notice] = "Asociación eliminada correctamente."
    else
      flash[:error] = "La asociación no existe."
    end
    
    redirect_to "/admin/ads_slots/edit/#{as.id}"
  end
  
  def require_user_can_owns_ads_slot(ads_slot_id)
    @user.is_superadmin? || !@user.users_roles.find(:first, :conditions => 'role = \'Advertiser\' AND role_data = \'#{ads_slot_id}\'').nil?
  end
end