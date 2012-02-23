class ForosController < ComunidadController
  allowed_portals [:gm, :faction, :clan, :bazar, :arena, :bazar_district]
  acts_as_content_browser :topic

  TOPLEVEL_GROUPS = [['Gamersmafia', 'gm'],
      ['Juegos', 'juegos'],
      ['Plataformas', 'plataformas'],
      ['Arena', 'arena'],
      ['Bazar', 'bazar'],
      ]

  def index
  end

  def nuevo_topic
    require_auth_users
    @title = 'Nuevo tópic'
    if params[:forum_id]
      @forum = Term.find_taxonomy(params[:forum_id], 'TopicsCategory')
      @forum = Term.single_toplevel(:id => params[:forum_id]) if @forum.nil?
    end
  end

  def mis_foros

  end

  def forum
    # TODO no chequeamos que sea un foro correcto para este portal
    @forum = Term.find_taxonomy(params[:id], 'TopicsCategory')
    @forum = Term.single_toplevel(:id => params[:id]) if @forum.nil?
    raise ActiveRecord::RecordNotFound if @forum.nil?

    forum_for_title = @forum
    @title = ''
    @navpath = [] # [['Foros', '/foros'], [@forum.parent.name]

    # TODO usar get_category_ascendants y print_forum_path
    # TODO pintar la ruta completa de acceso
    while forum_for_title != nil do
      @title = forum_for_title.name  + ' &raquo; ' + @title
      @navpath<< [forum_for_title.name, "/foros/forum/#{forum_for_title.id}"]
      forum_for_title = forum_for_title.parent
    end

    @navpath<< ['Foros', '/foros']
    @navpath.reverse!

    if !@forum.parent then # TODO little hack
      @navpath = [['Foros', '/foros'], [@forum.name, "/foros/forum/#{@forum.id}"]]
      category
      render :action => 'category'
    end
  end

  def category
  end

  def topic
    @topic = Topic.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @topic.is_public? or (user_is_authed and Cms::user_can_edit_content?(@user, @topic))
    obj = @topic
    # TODO las 4 líneas siguientes duplicadas en acts_as_content_browser
    if "http://#{request.host}#{request.fullpath}".index(gmurl(obj)).nil?
      redirect_to(obj.unique_content.url, :status => 301) and return
    end

    @forum = @topic.terms.find(:first, :conditions => 'taxonomy = \'TopicsCategory\'')

    raise ActiveRecord::RecordNotFound unless @forum
    @title = @topic.title
    @navpath = [['Foros', '/foros']]
    @forum.get_ancestors.reverse.each { |p| @navpath<< [p.name, "/foros/forum/#{p.id}"] }

    @navpath<<[@forum.name, "/foros/forum/#{@forum.id}"]
    @navpath<<[@topic.title, gmurl(@topic)]
    track_item(@topic)
  end


  def edit
    @topic = Topic.find(params[:id])
    require_user_can_edit(@topic)
    @forum = @topic.main_category
    @title = "Editar #{@topic.title}"
    @navpath = [['Foros', '/foros'], [@forum.parent.name, "/foros/forum/#{@forum.parent.id}"], [@forum.name, "/foros/forum/#{@forum.id}"], [@topic.title, gmurl(@topic)], ['Editar', "/foros/edit/#{@topic.id}"]]
    @topic = @topic
  end

  def update_topic
    require_auth_users
    @topic = Topic.find(params[:topic]['id'])
    require_user_can_edit(@topic)
    params[:topic][:main] = Comments::formatize(params[:topic][:main])

    @topic.cur_editor = @user
    if @topic.update_attributes(params[:topic])
      flash[:notice] = 'Topic actualizado correctamente.'
      redirect_to :action => 'topic', :id => @topic
    else
      render :action => 'edit'
    end
  end

  def move_topic
    require_auth_users
    @topic = Topic.find(params[:topic]['id'])
    require_user_can_edit(@topic)
    # chequear que no lo esté intentando mover a una categoría prohibida
    newt = Term.find(:first, :conditions => ['id = ? AND taxonomy = \'TopicsCategory\'', params[:categories_terms][0]])
    raise ActiveRecord::RecordNotFound unless newt
    @topic.terms.each { |t| t.unlink(@topic.unique_content) }
    newt.link(@topic.unique_content)
    params[:topic][:moved_on] = Time.now
    @topic.cur_editor = @user
    if @topic.update_attributes(params[:topic])
      flash[:notice] = 'Topic movido correctamente.'
      redirect_to :action => 'topic', :id => @topic
    else
      render :action => 'edit'
    end
  end

  def create_topic
    require_auth_users

    raise ActiveRecord::RecordNotFound if params[:topic].nil?

    params[:topic][:user_id] = @user.id
    params[:topic][:main] = Comments::formatize(params[:topic][:main])

    raise "terms must be single forum" unless params[:categories_terms] && params[:categories_terms].size == 1
    forum = Term.find_taxonomy(params[:categories_terms][0].to_i, 'TopicsCategory')

    @topic = Topic.new(params[:topic])

    if forum.nil? then
      flash[:error] = 'Debes elegir un foro'
      render :action => 'nuevo_topic'
    elsif forum.id == forum.root_id then
      flash[:error] = 'Imposible publicar topic en el foro especificado'
      render :action => 'nuevo_topic'
    else
      if @user.created_on > 1.day.ago && @user.topics.count > 1 then
        flash[:error] = "Para evitar spam las cuentas recién creadas solo pueden crear un tópic el primer día."
        render :action => 'nuevo_topic'
      elsif @user.topics.count(:conditions => "created_on >= now() - '5 days'::interval AND sticky is false AND state = #{Cms::PUBLISHED} AND cache_comments_count = 0") > 3 then
        flash[:error] = "Tienes demasiados tópics abiertos sin que otros usuarios hayan respondido, debes esperar un poco antes de publicar un nuevo tópic."
        render :action => 'nuevo_topic'
      else
        fac = Faction.find_by_code(forum.root.code)
        if fac && !FactionsBannedUser.find(:first, :conditions => ['user_id = ? AND faction_id = ?', @user.id, fac.id]).nil?
          flash[:error] = "Permiso denegado: Estás baneado de la facción #{fac.name}."
          redirect_to '/foros'
        elsif @topic.save
          forum.link(@topic.unique_content)
          begin
            Comments.require_user_can_comment_on_content(@user, @topic)
          rescue Exception => e
            # TODO aquí habría que no crearlo directamente, hay que refactorizar los permisos
            flash[:error] = "Permiso denegado"
            @topic.change_state(Cms::DELETED, User.find_by_login('MrMan'))
            redirect_to '/foros'
          else
            flash[:notice] = 'Tópic creado correctamente.'
            # no es una tonter:ia quitarlo, lo dejamos que se añada para que no le salga como nuevo elemento pendiente de leer
            Users.remove_from_tracker(@user, @topic.unique_content) if params[:add_to_tracker] != '1'
            redirect_to :action => 'topic', :id => @topic
          end

        else
          flash[:error] = @topic.errors.full_messages.join('<br />')
          render :action => 'nuevo_topic'
        end
      end
    end
  end

  def destroy
    @topic = Topic.find(params[:id])
    require_user_can_edit(@topic)
    Cms::modify_content_state(@topic, @user, Cms::DELETED)
    #@topic.mark_as_deleted(@user)
    redirect_to '/foros'
  end
end
