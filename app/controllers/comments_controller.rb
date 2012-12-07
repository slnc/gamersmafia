# -*- encoding : utf-8 -*-
require "base64"
class CommentsController < ApplicationController
  before_filter :require_auth_users

  def upload_img
    if params[:image_url]
      new_html = Cms.parse_images(
          "<img src=\"#{params[:image_url]}\" />",
          @user.users_files_dir_relative)
      @uploaded_img_path = new_html.match(/src="([^"]+)"/)[1]
    elsif params[:image]
      @uploaded_img_path = @user.upload_b64_filedata(params[:image])
    else
      raise "Unable to upload img. No 'image' or 'image_url' params."
    end

    render :layout => false
  end

  def create
    params[:comment] ||= {}
    params[:comment][:content_id] ||= 0

    if params[:images]
      params[:comment][:comment] = (
          "#{params[:comment][:comment]}\n" +
          "#{Comment.images_to_comment(params[:images], @user)}")
    end

    content = Content.find(params[:comment][:content_id])
    object = content

    if params[:redirto].to_s == '' || /create/ =~ params[:redirto]
      params[:redirto] = '/'
    end

    begin
      Comments.require_user_can_comment_on_content(@user, object)
    rescue Exception => e
      Rails.logger.warn("User #{@user} cannot comment on #{object}: #{e}")
      flash[:error] = e.to_s
      redirect_to(params[:redirto]) && return
    end

    # Buscamos el último comentario y si es nuestro y de menos de 1h lo
    # editamos en lugar de crear uno nuevo.
    last_comment = content.comments.find(
        :first, :conditions => "deleted = 'f'", :order => 'id DESC')
    append_to_last = (
        last_comment &&
        last_comment.user_id == @user.id &&
        last_comment.created_on >= 1.hour.ago &&
        !last_comment.moderated?
    )

    if append_to_last
      if (last_comment.comment == params[:comment][:comment])
        # Ha hecho doble click en enviar comentario
        flash[:notice] = 'Comentario añadido correctamente'
      else

        if last_comment.append_update(params[:comment][:comment])
          flash[:notice] = 'Comentario añadido correctamente'
        else
          flash[:error] = ("Ocurrió un error al guardar el comentario:" +
                           " <br /> #{last_comment.errors.full_messages_html}")
        end
      end
      redirect_to(params[:redirto]) && return
    end

    # si el último comentario de este usuario es de hace menos de 15
    # segundos le bloqueamos
    # TODO(slnc): move to authorization lib
    if @user.comments.count(
        :conditions => "created_on > now() - '15 seconds'::interval") > 0
      flash[:error] = (
          "Debes esperar al menos 15 segundos antes de publicar un nuevo" +
          " comentario")
      redirect_to(params[:redirto]) && return
    elsif (@user.created_on > 1.day.ago &&
           @user.comments.count(
             :conditions => "created_on > now() - '1 hour'::interval") > 10)
      flash[:error] = (
        "No puedes publicar tantos comentarios seguidos, inténtalo un" +
        " poco más tarde.")
      redirect_to(params[:redirto]) && return
    end

    @comment = Comment.new({
        :comment => params[:comment][:comment],
        :content_id => params[:comment][:content_id],
        :host => self.remote_ip,
        :user_id => @user.id,
    })
    if @comment.save
      if params[:add_to_tracker] && params[:add_to_tracker] == '1'
        Users.add_to_tracker(@user, @comment.content)
      end
      flash[:notice] = 'Comentario añadido correctamente'
    else
      flash[:error] = (
          "Ocurrió un error al guardar el comentario: <br />" +
          "#{@comment.errors.full_messages_html}")
    end

    redirect_to(params[:redirto])
  end

  def edit
    @title = 'Editando comentario'
    @comment = Comment.find(params[:id])
    if not @comment.can_edit_comment?(@user)
      params[:redirto] = '/' if params[:redirto].nil?
      redirect_to params[:redirto]
    end
  end

  def update
    @comment = Comment.find(params[:id])
    if @comment.can_edit_comment?(@user, true)
      @comment.comment = params[:comment][:comment]
      @comment.lastedited_by_user_id = @user.id

      if @comment.save
        cur_page = @comment.comment_page
        flash[:notice] = 'Comentario modificado correctamente'
        redirect_to "#{params[:redirto]}?page=#{cur_page}#comment#{@comment.id}"
      else
        render :action => 'edit'
      end
    end
  end

  def redir
    comment = Comment.find(params[:id])
    redirect_to "#{Routing.gmurl(comment.content)}?page=#{comment.comment_page}#comment#{comment.id}"
  end

  def rate
    # TODO controls
    @comment = Comment.find(params[:comment_id])
    if @comment.can_be_rated_by?(@user)
      @cvt = CommentsValorationsType.find(params[:rate_id])
      if (@cvt.positive? && !Authorization.can_rate_comments_up?(@user) ||
         (@cvt.negative? && !Authorization.can_rate_comments_down?(@user)))
        flash[:error] = (
            "No puedes valorar este comentario con las opciones elegidas.")
        @disable_ratings = true
      else
        @comment.delay.rate(@user, @cvt)
        @disable_ratings = (@user.remaining_rating_slots - 1 <= 0)
      end
    else
      Rails.logger.warn("User #{@user.login} can't rate comment #{@comment.id}")
      @disable_ratings = true
      @cvt = CommentsValorationsType.new({:name => 'Ninguna'})
    end

    render :layout => false, :action => 'rate'
  end

  def report
    @comment = Comment.find(params[:id])
    if Authorization.can_report_comments?(@user)
      @comment.report_violation(@user, params[:moderation_reason].to_i)
      if @comment.errors.size > 0
        flash[:error] = "Error al reportar el comentario:<br />#{@comment.errors.full_messages_html}"
      else
        flash[:notice] = "Comentario reportado correctamente"
      end

      render :partial => '/shared/ajax_facebox_feedback', :layout => false
    else
      raise AccessDenied
    end
  end

  def no_violation
    @comment = Comment.find(params[:id])
    raise AccessDenied unless Authorization.can_moderate_comment?(@user, @comment)
    @comment.update_attributes(
        :netiquette_violation => false, :lastedited_by_user_id => @user.id)

    @js_response = "$('#comment#{@comment.id}').fadeOut('normal');"
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end

  def violaciones_netiqueta
    raise AccessDenied unless Authorization.can_see_netiquette_violations?(@user)
  end

  private
  def upload_img_to_user(data_b64_encoded)

  end
end
