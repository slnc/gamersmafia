class AdsController < ApplicationController
  before_filter :check_perms

  def index
    redirect_to "/home/anunciante"
  end

  def slot
    @ads_slot = AdsSlot.find(params[:id])
    require_user_can_owns_ads_slot(@ads_slot)
  end

  def create
    @ad = Ad.new(params[:ad])
    @ad.advertiser_id = @user.users_roles.find(:first, :conditions => 'role = \'Advertiser\'', :order => 'id').role_data.to_i
    if @ad.save
      flash[:notice] = 'Ad creado correctamente.'
      @ads_slot = AdsSlot.find(params[:ads_slot_id])
      require_user_can_owns_ads_slot(@ads_slot)
      @ads_slot.ads_slots_instances.create(:ad_id => @ad.id)
    end
    redirect_to params[:redirto] ? params[:redirto] : "/ads/slot/#{@ads_slot.id}"
  end

  def edit
    @ad = Ad.find(params[:id])
    require_user_can_edit_ad
  end

  def update
    @ad = Ad.find(params[:id])
    require_user_can_edit_ad
    if @ad.update_attributes(params[:ad])
      flash[:notice] = 'Ad actualizado correctamente.'
      redirect_to :action => 'edit', :id => @ad
    else
      render :action => 'edit'
    end
  end

  def destroy
    @ad = Ad.find(params[:id])
    require_user_can_edit_ad
    User.db_query("UPDATE ads_slots_instances SET deleted = 't' WHERE ad_id = #{@ad.id}")
    # @ad.ads_slots_instances.find(:first, :conditions => ['ads_slot_id = ?', @as.id]).update_attributes(:deleted => true)
    flash[:notice] = "Banner borrado correctamente"
    redirect_to "/home/anunciante"
  end

  def check_perms
    raise AccessDenied unless user_is_authed && @user.has_admin_permission?(:advertiser)
  end

  def require_user_can_owns_ads_slot(ads_slot)
    @user.is_superadmin? || !@user.users_roles.find(:first, :conditions => 'role = \'Advertiser\' AND role_data = \'#{ads_slot.advertiser_id}\'', :order => 'id').nil?
  end

  def require_user_can_edit_ad
    @as = @ad.ads_slots_instances.find(:first, :conditions => 'deleted = \'f\'')
    raise AccessDenied unless @as
    require_user_can_owns_ads_slot(@as)
  end
end
