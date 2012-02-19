class Cuenta::ComentariosController < ApplicationController

  def index
    require_auth_users
  end

  def save
    require_auth_users
    @user.comments_sig = params[:user][:comments_sig].to_s.strip
    @user.pref_comments_autoscroll = params[:user][:pref_comments_autoscroll].to_s.strip
    @user.comment_show_sigs = params[:user][:comment_show_sigs]
    if @user.save
      flash[:notice] = "Cambios guardados correctamente."
    else
      flash[:error] = "Error al guardar la firma: #{@user.errors.full_messages_html}"
    end
    redirect_to '/cuenta/comentarios'
  end
end
