class Admin::CanalesController < AdministrationController
  audit :del, :reset
  
  def index
  end
  
  def info
    @gmtv_channel = GmtvChannel.find(params[:id])
  end
  
  def del
    @gmtv_channel = GmtvChannel.find(params[:id])
    @gmtv_channel.destroy
    # act_and_flash @gmtv_channel, :destroy, 'cabecera', 'borrada', 'borrar'
    if @gmtv_channel.frozen?
      flash[:notice] = "Cabecera borrada correctamente"
    else
      flash[:error] = "Error al intentar borrar: #{@gmtv_channel.errors.full_messages_html}"
    end
    redirect_to :action => :index
  end
  
  def reset
    @gmtv_channel = GmtvChannel.find(params[:id])
    @gmtv_channel.file = nil
    if @gmtv_channel.save
      flash[:notice] = "Cabecera reseteada correctamente"
      if params[:notify] && params[:notify].to_i == 1 
        Message.create({:user_id_from => @user.id, :user_id_to => @gmtv_channel.user_id, :title => 'Cabecera reseteada', :message => "Tu cabecera con Id <strong>#{@gmtv_channel.id}</strong> ha sido reseteada por la siguiente razón: \"<strong>#{params[:reset_reason]}\"</strong>"})
      end
    else
      flash[:error] = "Error al intentar resetear: #{@gmtv_channel.errors.full_messages_html}"
    end
    redirect_to "/admin/canales/info/#{params[:id]}"
  end
end
