class Cuenta::MisCanalesController < ApplicationController
  before_filter :require_auth_users

  def index
    @title = "Mis canales GMTV"
  end

  def editar
    @title = "Editar canal"
    @gmtv_channel = @user.gmtv_channels.find_by_id(params[:id])
    raise ActiveRecord::RecordNotFound unless @gmtv_channel
  end

  def update
    @gmtv_channel = @user.gmtv_channels.find_by_id(params[:id])
    raise ActiveRecord::RecordNotFound unless @gmtv_channel
    if @gmtv_channel.update_attributes(params[:gmtv_channel])
      flash[:notice] = "Canal actualizado correctamente"
    else
      flash[:error] = "Error al actualizar el canal: #{@gmtv_channel.errors.full_messages_html}"
    end
    redirect_to "/cuenta/mis_canales/editar/#{@gmtv_channel.id}"
  end
end
