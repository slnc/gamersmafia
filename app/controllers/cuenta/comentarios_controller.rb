# -*- encoding : utf-8 -*-
class Cuenta::ComentariosController < ApplicationController

  def index
    require_auth_users
  end

  def save
    require_auth_users
    @user.comments_sig = params[:user][:comments_sig].to_s.strip
    @user.comment_show_sigs = params[:user][:comment_show_sigs]
    @user.pref_comments_autoscroll = parse_bool_preference(
        params[:user][:pref_comments_autoscroll])
    @user.pref_show_all_comments = parse_bool_preference(
        params[:user][:pref_show_all_comments])
    @user.pref_use_elastic_comment_editor = parse_bool_preference(
        params[:user][:pref_use_elastic_comment_editor])

    if @user.save
      flash[:notice] = "Cambios guardados correctamente."
    else
      flash[:error] = (
          "Error al guardar la firma: #{@user.errors.full_messages_html}")
    end
    redirect_to '/cuenta/comentarios'
  end

  protected
  # Returns true if the given preference has been chosen and false otherwise.
  def parse_bool_preference(value)
    (value.to_s.strip == '1') ? '1' : '0'
  end
end
