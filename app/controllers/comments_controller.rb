class CommentsController < ApplicationController
  before_filter :require_auth_users
  
  verify :method => :post, :params => [ :comment ], :only => :create, :redirect_to => '/'
  
  def create
    content = Content.find(params[:comment][:content_id])
    object = content.real_content
    
    begin
      Comments.require_user_can_comment_on_content(@user, object)
    rescue Exception => e
      flash[:error] = e.to_s
    else
      # buscamos el último comentario y si es nuestro y de menos de 1h lo editamos en lugar de crear
      last_comment = content.comments.find(:first, :conditions => 'deleted = \'f\'', :order => 'id DESC')
      if last_comment && last_comment.user_id == @user.id && last_comment.created_on >= 1.hour.ago then
        if last_comment.comment == Comments::formatize(params[:comment][:comment]) then
          # para evitar doble clicks a enviar comentario
          flash[:notice] = 'Comentario añadido correctamente' 
        else
          last_comment.comment = "#{last_comment.comment}<br /><br /><strong>Editado</strong>: #{Comments::formatize(params[:comment][:comment])}"
          if last_comment.save
            flash[:notice] = 'Comentario añadido correctamente'
          else
            flash[:error] = "Ocurrió un error al guardar el comentario: <br /> #{last_comment.errors.full_messages_html}"
          end  
        end
      else
        # si el último comentario de este usuario es de hace menos de 15 segundos le bloqueamos
        if @user.comments.count(:conditions => 'created_on > now() - \'15 seconds\'::interval') > 0 then
          flash[:error] = "Debes esperar al menos 15 segundos antes de publicar un nuevo comentario"
        elsif @user.created_on > 1.day.ago && @user.comments.count(:conditions => 'created_on > now() - \'1 hour\'::interval') > 10 then
          flash[:error] = "No puedes publicar tantos comentarios seguidos, inténtalo un poco más tarde."
        else
          @comment = Comment.new({:content_id => params[:comment][:content_id], 
            :user_id => @user.id, 
            :host => request.remote_ip, 
            :comment => Comments::formatize(params[:comment][:comment])})
          
          if @comment.save
            Users.add_to_tracker(@user, @comment.content) if params[:add_to_tracker] && params[:add_to_tracker] == '1'
            flash[:notice] = 'Comentario añadido correctamente' 
          else
            flash[:error] = "Ocurrió un error al guardar el comentario: <br /> #{@comment.errors.full_messages_html}"
          end
        end
      end
    end  
    
    params[:redirto] = '/' if params[:redirto].to_s == '' or /create/ =~ params[:redirto] 
    redirect_to params[:redirto] # tenemos que redirigir siempre ya que se crean desde distintas páginas
  end
  
  def destroy
    @comment = Comment.find(params[:id])
    require_user_can_edit(@comment)
    # TODO copypaste de laflecha
    cur_page = Comments.page_for_comment(@comment)
    prev_comment = Comments.find_prev_comment(@comment)
    anchor = prev_comment ? "comment#{prev_comment.id}" : 'comments'
    
    if prev_comment and Comments.page_for_comment(prev_comment) < cur_page then # caso especial, cambio de pág?
      if Comment.count(:conditions => ['id > ? and content_id = ?', params[:id].to_i, params[:content_id]]) > 0 # más comentarios en la página de la que hemos borrado el comment
        anchor = 'comments'
      else # no hay más comentarios después, redirigimos a la página del comentario ant
        cur_page = Comments.page_for_comment(prev_comment)
      end
    end
    
    @comment.mark_as_deleted
    flash[:notice] = 'Comentario borrado correctamente'
    if params[:redirto] then
      if cur_page
        redirect_to "#{params[:redirto]}?page=#{cur_page}##{anchor}"
      else
        redirect_to params[:redirto]
      end
    else
      redirect_to '/'
    end
  end
  
  def edit
    @title = 'Editando comentario'
    @comment = Comment.find(params[:id])
    curuser_can_edit_comment = Cms::user_can_edit_content?(@user, @comment)
    
    if not Comments.user_can_edit_comment(@user, @comment, curuser_can_edit_comment)
      params[:redirto] = '/' if params[:redirto].nil?
      redirect_to params[:redirto]
    end
  end
  
  def update
    @comment = Comment.find(params[:id])
    curuser_can_edit_comment = Cms::user_can_edit_content?(@user, @comment)
    if Comments.user_can_edit_comment @user, @comment, curuser_can_edit_comment, true
      @comment.comment = Comments::formatize(params[:comment][:comment])
      @comment.netiquette_violation = (params[:comment][:netiquette_violation] || false)
      @comment.lastedited_by_user_id = @user.id
      
      if @comment.save
        cur_page = Comments.page_for_comment(@comment)
        flash[:notice] = 'Comentario modificado correctamente'
        redirect_to "#{params[:redirto]}?page=#{cur_page}#comment#{@comment.id}"
      else
        render :action => 'edit'
      end
    end
  end
  
  def rate
    # TODO controls
    @comment = Comment.find(params[:comment_id])
    if Comments.user_can_rate_comment(@user, @comment)
      @cvt = CommentsValorationsType.find(params[:rate_id])
      @disable_ratings = ((@user.remaining_rating_slots - 1) <= 0) ? true : false
      GmSys.job("Comment.find(#{@comment.id}).rate(User.find(#{@user.id}), CommentsValorationsType.find(#{params[:rate_id]}))")
    else
      @disable_ratings = true
      @cvt = CommentsValorationsType.new({:name => 'Ninguna'})
    end
    
    render :layout => false, :action => 'rate'
    #    flash[:notice] = "Comentario valorado correctamente como <strong>#{cvt.name}</strong>"
    #    params[:redirto] = '/' if params[:redirto].nil?
    #    redirect_to params[:redirto]
  end
  
  def report
    @comment = Comment.find(params[:id])
    if Comments.user_can_report_comment(@user, @comment)
      org = Organizations.find_by_content(@comment)
      if org
        ttype = org.class.name == 'Faction' ? :faction_comment_report : :bazar_district_comment_report
        scope = org.id
      else
        ttype = :general_comment_report
        scope = nil
      end
      reason_str = (params[:reason] && params[:reason].to_s != '' && params[:reason].to_s != 'Razón..') ? " (#{params[:reason]})" : '' 
      sl = SlogEntry.create({:scope => scope, :type_id => SlogEntry::TYPES[ttype], :reporter_user_id => @user.id, :headline => "#{Cms.faction_favicon(@comment.content.real_content)}<strong><a href=\"#{url_for_content_onlyurl(@comment.content.real_content)}?page=#{Comments.page_for_comment(@comment)}#comment#{@comment.id}\">#{@comment.id}</a></strong> (<a href=\"#{gmurl(@comment.user)}\">#{@comment.user.login}</a>) reportado #{reason_str} por <a href=\"#{gmurl(@user)}\">#{@user.login}</a>"})
      if sl.new_record?
        flash[:error] = "Error al reportar el comentario:<br />#{sl.errors.full_messages_html}"
      else
        flash[:notice] = "Comentario reportado correctamente"
      end
      render :partial => '/shared/ajax_facebox_feedback', :layout => false
    else
      raise AccessDenied
    end
  end
end
