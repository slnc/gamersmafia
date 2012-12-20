# -*- encoding : utf-8 -*-
class Admin::AdsSlotsController < AdministrationController

  before_filter do |c|
    require_authorization(:can_edit_ads_directly?)
  end

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
    @as = @ads_slot_orig.populate_copy(params[:ads_slot])
    if @as.save
      params[:ads] = @ads_slot_orig.ads.collect { |ad| ad.id }
      _update_slots_instances
      flash[:notice] = 'AdsSlot copiado correctamente.'
      redirect_to :action => 'index'
    else
      flash[:error] = "Error al crear el AdsSlot: #{@as.errors.full_messages_html}"
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
    @as.update_slots_instances(params[:ads].each do |ad| ad.to_i end)
  end

  def update_slots_instances
    @as = AdsSlot.find(params[:id])
    _update_slots_instances
    redirect_to "/admin/ads_slots/edit/#{@as.id}"
  end
end
