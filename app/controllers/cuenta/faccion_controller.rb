class Cuenta::FaccionController < ApplicationController
  before_filter :require_auth_users
  
  def user_is_boss(user, faction)
    if ((faction.boss and faction.boss.id == user.id) or 
     (faction.underboss and faction.underboss.id == user.id))
      true
    else
      false
    end
  end
  
  def submenu
    if @faction and (user_is_boss(@user, @faction) or @faction.is_editor?(@user)) then
      return 'Facción'
    else
      return nil
    end
  end
  
  def submenu_items
    l = [] 
    if @faction and (user_is_boss(@user, @faction) or @user.is_superadmin) then
      l<<['Información', '/cuenta/faccion/informacion']
      l<<['Staff', '/cuenta/faccion/staff']
      l<<['Foros', '/cuenta/faccion/foros']
      l<<['Cabeceras', '/cuenta/faccion/cabeceras']
      l<<['Links', '/cuenta/faccion/links']
      l<<['Mapas del juego', '/cuenta/faccion/mapas_juegos']
      l<<['Bans', '/cuenta/faccion/bans']
      l<<['Juego', '/cuenta/faccion/juego'] if @faction.game # TODO save this on the model
    end
    
    if @faction and @faction.is_editor?(@user) then
      l<<['Categorías de contenidos', '/cuenta/faccion/categorias']
    end
    
    l
  end
  
  def index
    @title = 'Facción'
    @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion']]
    if @user.faction_id then
      @faction = @user.faction
    end
  end
  
  def staff
    @title = 'Staff de facción'
    @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion'], ['Staff', '/cuenta/faccion/staff']]
    require_auth_faction_leader
    @editors = @faction.editors
    @moderators = @faction.moderators
  end
  
  
  def add_editor
    require_auth_faction_leader
    ctype = ContentType.find(params[:content_type_id].to_i)
    if ['funthing', 'topic'].include?(ctype.name.to_s.downcase) then
      flash[:error] = 'El tipo de contenido elegido no es válido.'
      redirect_to :action => 'staff'
    end
    
    @editors = @faction.editors
    @moderators = @faction.moderators
    
    user = User.find_by_login(params[:login])
    if user
      if @faction.add_editor(user, ctype)
        flash[:notice] = 'Editor añadido correctamente'
        redirect_to :action => 'staff'
      else
        flash[:error] = "Error al añadir al usuario #{params[:login]} como editor de #{ctype.name}"
        render :action => 'staff'
      end
    else
      flash[:error] = "El usuario \"#{params[:login]}\" no existe."
      render :action => 'staff'
    end
  end
  
  # TODO cambiar esta nomenclatura
  def add_moderator
    require_auth_faction_leader
    user = User.find_by_login(params[:login])
    if user.nil?
      flash[:error] = "El usuario \"#{params[:login]}\" no existe."
      render :action => 'staff'
    else
      if @faction.add_moderator(user)
        flash[:notice] = 'Moderador añadido correctamente'
        redirect_to :action => 'staff'
      else
        flash[:error] = 'Error al añadir moderador'
        render :action => 'staff'
      end
    end
  end
  
  def del_moderator
    require_auth_faction_leader
    @faction.del_moderator(User.find(params[:id].to_i))
    flash[:notice] = 'Moderador borrado correctamente'
    redirect_to :action => 'staff'
  end
  
  def del_editor
    require_auth_faction_leader
    @faction.del_editor(User.find(params[:id]), ContentType.find(params[:content_type_id].to_i))
    flash[:notice] = 'Editor borrado correctamente'
    redirect_to :action => 'staff'
  end
  
  
  def require_auth_faction_leader
    @faction = @user.faction
    raise AccessDenied unless @faction && (@user.is_superadmin || @faction.is_bigboss?(@user))
  end
  
  def join
    if @user.can_change_faction? then
      new_faction_id = params[:user].nil? ? params[:id] : params[:user][:id]
      
      Factions::user_joins_faction(@user, new_faction_id)
      if new_faction_id.nil? or new_faction_id == '' then
        flash[:notice] = "Has abandonado tu facción. Ahora eres un fugitivo, un alma en pena."
      else
        flash[:notice] = "Bienvenido a la facción #{@user.faction.name}"
      end
    end
    
    redirect_to :action => 'index'
  end
  
  def foros
    require_auth_faction_leader
    
    @forum = TopicsCategory.find(:first, :conditions => ["name = ? and root_id = id", @faction.name])
    #@topics_categories = @forum.children
    @topics_categories = TopicsCategory.find(:all, :conditions => ['root_id = ? and id <> ?', @forum.id, @forum.id], :order => 'root_id asc, parent_id desc, lower(name) asc')
  end
  
  def forum_new
    require_auth_faction_leader
    
    @forum = TopicsCategory.find(:first, :conditions => ["code = ? and root_id = id", @faction.code])
    @topics_categories = @forum.children
    @topics_category = TopicsCategory.new
    @topics_category.root_id = @forum.id
    @topics_category.parent_id = @forum.id
  end
  
  def forum_create
    # TODO validación
    require_auth_faction_leader
    
    @topics_category = TopicsCategory.new(params[:topics_category])
    if @topics_category.save
      expire_fragment(:controller => '/home', :action => 'index', :part => 'topics')
      flash[:notice] = 'Foro creado correctamente.'
      redirect_to '/cuenta/faccion/foros'
    else
      render :action => 'forum_new'
    end
    
  end
  
  def forum_edit
    # TODO validación
    require_auth_faction_leader
    
    @forum = TopicsCategory.find(:first, :conditions => ["name = ? and root_id = id", @faction.name])
    @topics_category = TopicsCategory.find(params[:id])
  end
  
  def forum_update
    # TODO validación
    require_auth_faction_leader
    
    @forum = TopicsCategory.find(:first, :conditions => ["name = ? and root_id = id", @faction.name])
    @topics_category = TopicsCategory.find(params[:id])
    if @topics_category.update_attributes(params[:topics_category])
      flash[:notice] = 'Foro actualizado correctamente.'
      redirect_to '/cuenta/faccion/foros'
    else
      render :action => 'edit'
    end
  end
  
  def forum_destroy
    # TODO validación
    require_auth_faction_leader
    
    @forum = TopicsCategory.find(:first, :conditions => ["name = ? and root_id = id", @faction.name])
    @topics_category = TopicsCategory.find(params[:id])
  end
  
  def forum_destroy_confirm
    # TODO validación
    require_auth_faction_leader
    
    @forum = TopicsCategory.find(:first, :conditions => ["name = ? and root_id = id", @faction.name])
    @topics_category = TopicsCategory.find(params[:id])
    
    if @topics_category.topics.count > 0 and params[:destination_forum_id] then
      @forum_destination = TopicsCategory.find(params[:destination_forum_id])
      
      for topic in @topics_category.topics
        topic.move_to_forum(@forum_destination)
      end
      
    elsif @topics_category.topics.count > 0 and not params[:destination_forum_id] then
      flash[:error] = 'No se ha especificado un foro de destino para los tópics existentes'
      throw :abort
    end
    
    @topics_category.destroy
    redirect_to '/cuenta/faccion/foros'
  end
  
  
  def categorias
    @faction = @user.faction
    @editable_content_types = []
    if params[:type_name] then
      if !@faction.user_is_editor_of_content_type?(@user, ContentType.find_by_name(params[:type_name])) then
        flash[:error] = 'Violación de seguridad. Hemos soltado a los perros..'
        throw :abort
      end
      @tld = self.get_cls(params[:type_name]).find(:first, :conditions => ["name = ? and root_id = id", @faction.name])
      @category_pages, @categories = paginate self.get_cls(params[:type_name]), :conditions => ['root_id = ? and id <> ?', @tld.id, @tld.id], :order => 'parent_id desc, lower(name) asc', :per_page => 50
      
      @title = "Editando categorías #{params[:type_name]}"
      @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion'], ['Categorias', '/cuenta/faccion/categorias'], [params[:type_name], "/cuenta/faccion/categorias/#{params[:type_name]}"]]
    else
      @categories = nil
      @title = 'Categorías de contenidos'
      @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion']]
    end
    
    for c in ContentType.find(:all, :conditions => 'name in (\'Image\', \'News\', \'Demo\', \'Download\', \'Review\', \'Tutorial\')')
      if @faction.user_is_editor_of_content_type?(@user, c) then
        @editable_content_types<< c
      end
    end
  end
  
  def categorias_edit
    @faction = @user.faction
    @tld = self.get_cls(params[:type_name]).find(:first, :conditions => ["name = ? and root_id = id", @faction.name])
    # Chequeamos los permisos creando un contenido en blanco asociado a la
    # categoría que estamos editando
    @category = self.get_cls(params[:type_name]).find(params[:id])
    @title = "Editando categoría #{params[:type_name]}: #{@category.name}"
    @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion'], ['Categorias', '/cuenta/faccion/categorias'], [params[:type_name], "/cuenta/faccion/categorias/#{params[:type_name]}"], [@category.name, "/cuenta/faccion/categorias/#{params[:type_name]}/edit/#{@category.id}"]]
    
    dummy = @category.class.items_class.new({"#{ActiveSupport::Inflector::underscore(@category.class.name)}_id" => @category.id})
    raise AccessDenied unless Cms::user_can_edit_content?(@user, dummy)
  end
  
  def categorias_destroy
    @faction = @user.faction
    @category = self.get_cls(params[:type_name]).find(params[:id])
    dummy = @category.class.items_class.new({"#{ActiveSupport::Inflector::underscore(@category.class.name)}_id" => @category.id})
    raise AccessDenied unless Cms::user_can_edit_content?(@user, dummy)
  end
  
  def categorias_new
    @faction = @user.faction
    @tld = self.get_cls(params[:type_name]).find(:first, :conditions => ["name = ? and root_id = id", @faction.name])
    @category = self.get_cls(params[:type_name]).new
    @category = @tld.children.new
    @category.root_id = @tld.id
    dummy = @category.class.items_class.new({"#{ActiveSupport::Inflector::underscore(@category.class.name)}_id" => @tld.id})
    raise AccessDenied unless Cms::user_can_edit_content?(@user, dummy)
  end
  
  def categorias_update
    @faction = @user.faction
    @category = self.get_cls(params[:type_name]).find(params[:id])
    @tld = self.get_cls(params[:type_name]).find(:first, :conditions => ["name = ? and root_id = id", @faction.name])
    dummy = @category.class.items_class.new({"#{ActiveSupport::Inflector::underscore(@category.class.name)}_id" => @tld.id})
    raise AccessDenied unless Cms::user_can_edit_content?(@user, dummy)
    
    if params[:category][:parent_id].empty? then
      flash[:error] = 'Imposible asignar a categoría en blanco'
      redirect_to "/cuenta/faccion/categorias/#{params[:type_name]}/edit/#{@category.id}"
    else
      if @category.update_attributes(params[:category])
        flash[:notice] = 'Categoría actualizada correctamente.'
        redirect_to "/cuenta/faccion/categorias/#{params[:type_name]}/edit/#{@category.id}"
      else
        flash[:error] = "Error al actualizar la categoría: #{@category.errors.full_messages_html}"
        render :action => 'categorias_edit'
      end
    end
  end
  
  def categorias_create
    @faction = @user.faction
    @tld = self.get_cls(params[:type_name]).find(:first, :conditions => ["name = ? and root_id = id", @faction.name])
    @category = self.get_cls(params[:type_name]).new(params[:category])
    @category.root_id = @tld.id
    dummy = @category.class.items_class.new({"#{ActiveSupport::Inflector::underscore(@category.class.name)}_id" => @tld.id})
    raise AccessDenied unless Cms::user_can_edit_content?(@user, dummy)
    
    if params[:category][:parent_id].empty? then
      flash[:error] = 'Imposible asignar a categoría en blanco'
      redirect_to "/cuenta/faccion/categorias/#{params[:type_name]}/new"
    elsif @category.save
      flash[:notice] = 'Categoría creada correctamente.'
      redirect_to "/cuenta/faccion/categorias/#{params[:type_name]}"
    else
      render :action => 'categorias_new'
    end
  end
  
  def category_destroy_confirm
    @faction = @user.faction
    @tld = self.get_cls(params[:type_name]).find(:first, :conditions => ["name = ? and root_id = id", @faction.name])
    # TODO validation
    @category = self.get_cls(params[:type_name]).find(params[:id])
    dummy = @category.class.items_class.new({"#{ActiveSupport::Inflector::underscore(@category.class.name)}_id" => @tld.id})
    raise AccessDenied unless Cms::user_can_edit_content?(@user, dummy)
    
    # TODO
    """
    if @category.topics.size > 0 and params[:destination_forum_id] then
      @category_destination = @category.class.find(params[:destination_category_id])
      # TODO whhhheee
      for topic in @category.topics
        topic.category_id = @forum_destination.id
        topic.save
      end
    elsif @category.topics.size > 0 and not params[:destination_forum_id] then
      flash[:error] = 'No se ha especificado un foro de destino para los tópics existentes'
      throw :abort
    end
    """
    if @category.items_count(nil, true) >= 50
      flash[:error] = "No se puede borrar la categoría ya que tiene más de 50 elementos."
    else
      @category.destroy
      flash[:notice] = 'Categoría eliminada correctamente.'
    end
    
    redirect_to "/cuenta/faccion/categorias/#{params[:type_name]}"
  end
  
  def get_cls(type_name)
    Cms.category_class_from_content_name(type_name)
  end
  
  def links
    require_auth_faction_leader
    @title = 'Links de facción'
    @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion'], ['Links de facción', '/cuenta/faccion/links']]
    
    @link_pages, @factions_links = paginate :factions_link, :conditions => "faction_id = #{@user.faction_id}", :order => 'lower(name) asc', :per_page => 30
  end
  
  def links_new
    require_auth_faction_leader
    @title = 'Nueva link'
    @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion'], ['links de facción', '/cuenta/faccion/links'], ['Nueva', '/cuenta/faccion/links/new']]
    @factions_link = FactionsLink.new({:faction_id => @user.faction_id})
  end
  
  def links_create
    require_auth_faction_leader
    @factions_link = FactionsLink.new(params[:factions_link])
    @factions_link.faction_id = @user.faction_id
    if @factions_link.save
      flash[:notice] = 'Enlace de facción creado correctamente.'
      redirect_to '/cuenta/faccion/links'
    else
      redirect_to '/cuenta/faccion/links/new'
    end
  end
  
  def links_edit
    require_auth_faction_leader
    @factions_link = FactionsLink.find(params[:id])
    @title = "Editando link: #{@factions_link.name}"
    @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion'], ['links de facción', '/cuenta/faccion/links'], ["Editar #{@factions_link.name}", "/cuenta/faccion/links/edit/#{@factions_link.id}"]]
    if @factions_link.faction_id != @user.faction_id then
      raise ActiveRecord::RecordNotFound
    end
  end
  
  def links_update
    require_auth_faction_leader
    @factions_link = FactionsLink.find(params[:id])
    if @factions_link.faction_id != @user.faction_id then
      raise ActiveRecord::RecordNotFound
    end
    
    if @factions_link.update_attributes(params[:factions_link])
      flash[:notice] = 'Enlace de facción actualizado correctamente.'
    end
    redirect_to "/cuenta/faccion/links/edit/#{@factions_link.id}"
  end
  
  def links_destroy
    require_auth_faction_leader
    @factions_link = FactionsLink.find(params[:id])
    if @factions_link.faction_id != @user.faction_id then
      raise ActiveRecord::RecordNotFound
    end
    if @factions_link.destroy
      flash[:notice] = 'Enlace de facción borrado correctamente.'
    end
    redirect_to '/cuenta/faccion/links/'
  end
  
  
  
  
  
  def cabeceras
    require_auth_faction_leader
    @title = 'Cabeceras de facción'
    @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion'], ['Cabeceras de facción', '/cuenta/faccion/cabeceras']]
    
    @header_pages, @factions_headers = paginate :factions_header, :conditions => "faction_id = #{@user.faction_id}", :order => 'lower(name) asc', :per_page => 30
  end
  
  def cabeceras_new
    require_auth_faction_leader
    @title = 'Nueva cabecera'
    @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion'], ['Cabeceras de facción', '/cuenta/faccion/cabeceras'], ['Nueva', '/cuenta/faccion/cabeceras/new']]
    @factions_header = FactionsHeader.new({:faction_id => @user.faction_id})
  end
  
  def cabeceras_create
    require_auth_faction_leader
    @factions_header = FactionsHeader.new(params[:factions_header])
    @factions_header.faction_id = @user.faction_id
    if @factions_header.save
      flash[:notice] = 'Cabecera de facción creada correctamente.'
      redirect_to '/cuenta/faccion/cabeceras'
    else
      redirect_to '/cuenta/faccion/cabeceras/new'
    end
  end
  
  def cabeceras_edit
    require_auth_faction_leader
    @factions_header = FactionsHeader.find(params[:id])
    @title = "Editando cabecera: #{@factions_header.name}"
    @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion'], ['Cabeceras de facción', '/cuenta/faccion/cabeceras'], ["Editar #{@factions_header.name}", "/cuenta/faccion/cabeceras/edit/#{@factions_header.id}"]]
    if @factions_header.faction_id != @user.faction_id then
      raise ActiveRecord::RecordNotFound
    end
  end
  
  def cabeceras_update
    require_auth_faction_leader
    @factions_header = FactionsHeader.find(params[:id])
    if @factions_header.faction_id != @user.faction_id then
      raise ActiveRecord::RecordNotFound
    end
    
    if @factions_header.update_attributes(params[:factions_header])
      flash[:notice] = 'Cabecera de facción actualizada correctamente.'
    end
    redirect_to "/cuenta/faccion/cabeceras/edit/#{@factions_header.id}"
  end
  
  def cabeceras_destroy
    require_auth_faction_leader
    @factions_header = FactionsHeader.find(params[:id])
    if @factions_header.faction_id != @user.faction_id then
      raise ActiveRecord::RecordNotFound
    end
    if @factions_header.destroy
      flash[:notice] = 'Cabecera de facción borrada correctamente.'
    end
    redirect_to '/cuenta/faccion/cabeceras/'
  end
  
  def informacion
    require_auth_faction_leader
    @title = 'Editar propiedades de facción'
    @faction = Faction.find(@user.faction_id)
    @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion'], ['Información', '/cuenta/faccion/informacion']]
  end
  
  def informacion_update
    require_auth_faction_leader
    @faction = Faction.find(@user.faction_id)
    if @faction.update_attributes(params[:faction])
      flash[:notice] = 'Cambios guardados correctamente'
    else
      flash[:error] = "Error al guardar los cambios: <br />#{@faction.errors.full_messages_html}"
    end
    redirect_to '/cuenta/faccion/informacion'
  end
  
  # TODO copypasted
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :mapas_juegos_destroy, :mapas_juegos_create, :mapas_juegos_update ],
  :redirect_to => { :action => :mapas_juegos_list }
  
  def mapas_juegos
    require_auth_faction_leader
    @title = 'Mapas de juegos'
    @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion'], ['Mapas del juego', '/cuenta/faccion/mapas_juegos']]
    # @navpath = [['Mapas de juegos', '/admin/mapas_juegos'],]
    @games_map_pages, @games_maps = paginate :games_maps, :conditions => "game_id = #{@user.faction.game.id}", :per_page => 50, :order => 'games_maps.game_id ASC, lower(games_maps.name) ASC', :include => :game
  end
  
  def mapas_juegos_new
    @title = 'Nuevo mapa del juego'
    @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion'], ['Mapas del juego', '/cuenta/faccion/mapas_juegos'], ['nuevo', '/cuenta/faccion/mapas_juegos/mapas_juegos_new']]
    require_auth_faction_leader
    @games_map = GamesMap.new
  end
  
  def mapas_juegos_create
    require_auth_faction_leader
    params[:games_map][:game_id] = @user.faction.game.id # TODO hell..
    if params[:games_map][:download_id].to_s != '' && Download.find_by_id(params[:games_map][:download_id].to_i).nil? then
      flash[:error] = 'La ID de descarga especificada no es válida.'
      render :action => 'mapas_juegos_new'
    else
      @games_map = GamesMap.new(params[:games_map]) # TODO restringir a los mapas de esta facción
      if @games_map.save
        flash[:notice] = 'Mapa de juego creado correctamente.'
        redirect_to :action => 'mapas_juegos'
      else
        flash[:error] = "Error al crear el mapa del juego: #{@games_map.errors.full_messages_html}"
        render :action => 'mapas_juegos_new'
      end
    end
  end
  
  def mapas_juegos_edit
    require_auth_faction_leader
    @games_map = GamesMap.find(params[:id])
    @title = "Editar #{@games_map.name}"
    @navpath = [['Cuenta', '/cuenta'], ['Facción', '/cuenta/faccion'], ['Mapas del juego', '/cuenta/faccion/mapas_juegos'], [@games_map.name, "/cuenta/faccion/mapas_juegos/mapas_juegos_editar/#{@games_map.id}"]]
  end
  
  def mapas_juegos_update
    require_auth_faction_leader
    @games_map = GamesMap.find(params[:id])
    params[:games_map][:game_id] = @user.faction.game.id # TODO hell..
    if params[:games_map][:download_id].to_s != '' && Download.find_by_id(params[:games_map][:download_id].to_i).nil? then
      flash[:error] = 'La ID de descarga especificada no es válida.'
      render :action => 'mapas_juegos_edit'
    else
      if @games_map.update_attributes(params[:games_map])
        flash[:notice] = 'Mapa de juego actualizado correctamente.'
        redirect_to :action => 'mapas_juegos_edit', :id => @games_map
      else
        flash[:error] = 'Error al guardar los cambios'
        render :action => 'mapas_juegos_edit'
      end
    end
  end
  
  def mapas_juegos_destroy
    require_auth_faction_leader
    GamesMap.find(:first, :conditions => "id = #{params[:id]} and game_id = #{@user.faction.game.id}").destroy
    redirect_to :action => 'mapas_juegos'
  end
  
  def bans
    require_auth_faction_leader
    @title = "Usuarios baneados de esta facción"
  end
  
  def ban_user
    require_auth_faction_leader
    u = User.find_by_login(params[:login].strip)
    raise ActiveRecord::RecordNotFound unless u
    b = @faction.factions_banned_users.create({:user_id => u.id, :banner_user_id => @user.id, :reason => params[:reason]})
    if b.new_record?
      flash[:error] = "Error al banear al usuario:<br />#{b.errors.full_messages_html}"
      bans
      render :action => 'bans'
    else
      flash[:notice] = "Usuario <strong>#{u.login}</strong> baneado correctamente"
      redirect_to :action => :bans
    end
  end
  
  def unban_user
    require_auth_faction_leader
    u = User.find_by_login(params[:login])
    raise ActiveRecord::RecordNotFound unless u
    b = @faction.factions_banned_users.find_by_user_id(u.id)
    if b
      b.destroy
      flash[:notice] = "Usuario desbaneado correctamente"
    else
      flash[:error] = "El usuario #{u.login} no estaba banado"
    end
    redirect_to :action => :bans
  end
  
  def juego
    require_auth_faction_leader
    raise ActiveRecord::RecordNotFound unless @faction.game
    @game = @faction.game
  end
  
  def create_games_version
    require_auth_faction_leader
    gm = GamesVersion.new(params[:games_version])
    if gm.save
      flash[:notice] = 'Versión de juego creada correctamente.'
    else
      flash[:error] = "Error al crear la versión: #{gm.errors.full_messages_html}"
    end
    
    redirect_to "/cuenta/faccion/juego"
  end
  
  def create_games_mode
    require_auth_faction_leader
    gm = GamesMode.new(params[:games_mode])
    if gm.save
      flash[:notice] = 'Modo de juego creado correctamente.'
    else
      flash[:error] = "Error al crear el modo de juego: #{gm.errors.full_messages_html}"
    end
    
    redirect_to '/cuenta/faccion/juego'
  end
  
  def destroy_games_version
    require_auth_faction_leader
    gv = GamesVersion.find(params[:id])
    if gv
      gv.destroy
      flash[:notice] = "Version #{gv.version} borrada correctamente"
    else
      flash[:error] = "Error al borrar la versión: #{gv.errors.full_messages_html}"
    end
    redirect_to "/cuenta/faccion/juego"
  end
  
  def destroy_games_mode
    require_auth_faction_leader
    gv = GamesMode.find(params[:id])
    if gv
      gv.destroy
      flash[:notice] = "Modo de juego #{gv.name} borrada correctamente"
    else
      flash[:error] = "Error al borrar el modo de juego: #{gv.errors.full_messages_html}"
    end
    redirect_to "/cuenta/faccion/juego"
  end
  
  def update_underboss
    require_auth_faction_leader
    
    if params[:login].to_s != ''
      thenew = User.find_by_login(params[:login])
      if thenew.nil?
        flash[:error] = "No se ha encontrado a ningun usuario con el nick <strong>#{params[:login]}</strong>"
        redirect_to '/cuenta/faccion/staff' and return
      end
       (redirect_to '/cuenta/faccion/staff' and return) if @faction.is_underboss?(thenew) 
      if thenew.users_roles.count(:conditions => ['role IN (?)', %w(Boss Underboss)]) > 0
        flash[:error] = "<strong>#{thenew.login}</strong> ya es boss o underboss de otra facción. Debe dejar su cargo actual antes de poder añadirlo como Underboss de <strong>#{@faction.name}</strong>"
        redirect_to '/cuenta/faccion/staff' and return
      end
      flash[:notice] = "Underboss <strong>#{params[:login]}</strong> guardado correctamente"
    else
      thenew = nil
      flash[:notice] = "Underboss eliminado correctamente."
    end
    
    @faction.update_underboss(thenew)
    redirect_to '/cuenta/faccion/staff'
  end
end
