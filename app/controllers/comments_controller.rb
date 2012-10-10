# -*- encoding : utf-8 -*-
class CommentsController < ApplicationController
  before_filter :require_auth_users

  def create
    params[:comment] ||= {}
    params[:comment][:content_id] ||= 0
    content = Content.find(params[:comment][:content_id])
    object = content.real_content

    begin
      Comments.require_user_can_comment_on_content(@user, object)
    rescue Exception => e
      Rails.logger.warn("User #{@user} cannot comment on #{object}: #{e}")
      flash[:error] = e.to_s
    else
      # buscamos el último comentario y si es nuestro y de menos de 1h lo
      # editamos en lugar de crear
      last_comment = content.comments.find(
          :first, :conditions => 'deleted = \'f\'', :order => 'id DESC')
      if (last_comment && last_comment.user_id == @user.id &&
          last_comment.created_on >= 1.hour.ago &&
          !last_comment.moderated?)
        if (last_comment.comment ==
            Comments::formatize(params[:comment][:comment]))
          # para evitar doble clicks a enviar comentario
          flash[:notice] = 'Comentario añadido correctamente'
        else
          last_comment.comment = (
              "#{last_comment.comment}<br /><br /><strong>Editado</strong>:" +
              " #{Comments::formatize(params[:comment][:comment])}")
          if last_comment.save
            flash[:notice] = 'Comentario añadido correctamente'
          else
            flash[:error] = ("Ocurrió un error al guardar el comentario:" +
                " <br /> #{last_comment.errors.full_messages_html}")
          end
        end
      else
        # si el último comentario de este usuario es de hace menos de 15
        # segundos le bloqueamos
        if @user.comments.count(
            :conditions => 'created_on > now() - \'15 seconds\'::interval') > 0
          flash[:error] = (
              "Debes esperar al menos 15 segundos antes de publicar un nuevo" +
              " comentario")
        elsif (@user.created_on > 1.day.ago &&
               @user.comments.count(
                 :conditions => "created_on > now() - '1 hour'::interval") > 10)
          flash[:error] = (
            "No puedes publicar tantos comentarios seguidos, inténtalo un" +
            " poco más tarde.")
        else
          @comment = Comment.new({
              :comment => Comments::formatize(params[:comment][:comment]),
              :content_id => params[:comment][:content_id],
              :host => self.remote_ip,
              :user_id => @user.id,
          })

          if @comment.save
            Users.add_to_tracker(@user, @comment.content) if params[:add_to_tracker] && params[:add_to_tracker] == '1'
            flash[:notice] = 'Comentario añadido correctamente'
          else
            flash[:error] = "Ocurrió un error al guardar el comentario: <br /> #{@comment.errors.full_messages_html}"
          end
        end
      end
    end

    if (params[:redirto].to_s == '' || /create/ =~ params[:redirto])
      params[:redirto] = '/'
    end
   # tenemos que redirigir siempre ya que se crean desde distintas páginas
    redirect_to params[:redirto]
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
      @comment.comment = Comments::formatize(params[:comment][:comment])
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

    @js_response = "$j('#comment#{@comment.id}').fadeOut('normal');"
    render :partial => '/shared/silent_ajax_feedback',
           :locals => { :js_response => @js_response }
  end

  def violaciones_netiqueta
    raise AccessDenied unless Authorization.can_see_netiquette_violations?(@user)
  end
end
