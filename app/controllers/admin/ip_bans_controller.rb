class Admin::IpBansController < ApplicationController  
  require_admin_permission :capo
  
  def index
    @ip_ban = IpBan.new({:expires_on => 7.days.since})
  end
  
  def create
    @ip_ban = IpBan.new(params[:ip_ban].merge(:user_id => @user.id))
    if @ip_ban.save
      flash[:notice] = 'Ban creado correctamente.'
      redirect_to :action => 'index'
    else
      flash[:error] = "Error al crear el ban: #{@ip_ban.errors.full_messages_html}" 
      render :action => 'index'
    end
  end
  
  def destroy
    IpBan.find(params[:id]).destroy
    flash[:notice] = "Ban borrado correctamente"
    redirect_to :action => 'index'
  end
end
