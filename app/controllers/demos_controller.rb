class DemosController < ArenaController
  acts_as_content_browser :demo
  allowed_portals [:gm, :faction, :clan, :arena]
  
  def index
    @title = 'Demos'
    
    #    parent_id = params[:category]
    #    if parent_id then
    #      @category = portal.demo.category_class.find(parent_id)
    #      paths, navpath = @category.get_category_address
    #      @title = paths.join(' &raquo; ')
    #    end
  end
  
  def buscar
    redirect_to :action => 'index' and return false unless params[:demo] #.kind_of? Hash)
    @title = 'Resultados de la búsqueda'
    sql_conds = []
    %w(demos_category_id demotype pov_type games_mode_id event_id games_version_id games_map_id entity1_local_id entity2_local_id).each do |attr|
      next unless params[:demo][attr.to_sym].to_s != ''
      sql_conds<< "#{attr} = #{params[:demo][attr.to_sym].to_i}"
    end
    
    if params[:demo][:entity].to_s != '' then
      q = "entity1_external = #{User.connection.quote(params[:demo][:entity])} OR entity2_external = #{User.connection.quote(params[:demo][:entity])}"
      if params[:demo][:games_mode_id] then
        gmod = GamesMode.find(params[:demo][:games_mode_id])
        if gmod.entity_type == Game::ENTITY_USER then
          u = User.find_by_login(params[:demo][:entity])
          q<< " OR entity1_local_id = #{u.id} OR entity2_local_id = #{u.id}"
        else
          c = Clan.find(:all, :conditions => ['lower(name) = lower(?) OR lower(tag) = lower(?)', params[:demo][:entity], params[:demo][:entity]], :limit => 10)
          c.each { |clan| q<< " OR entity1_local_id = #{clan.id} OR entity2_local_id = #{clan.id}" }
        end
      else
        u = User.find_by_login(params[:demo][:entity])
        q<< " OR entity1_local_id = #{u.id} OR entity2_local_id = #{u.id}"
        c = Clan.find(:all, :conditions => ['lower(name) = lower(?) OR lower(tag) = lower(?)', params[:demo][:entity], params[:demo][:entity]], :limit => 10)
        c.each { |clan| q<< " OR entity1_local_id = #{clan.id} OR entity2_local_id = #{clan.id}" }
      end
      sql_conds<< "(#{q})"
    end
    
    sql_conds<< "entity1_external = #{User.connection.quote(params[:demo][:entity_external])} OR entity2_external = #{User.connection.quote(params[:demo][:entity_external])}" if params[:demo][:entity_external]
    
    
    
    @demos = portal.demo.find(:published, :conditions => sql_conds.join(' AND '), :limit => 51, :order => 'created_on')
    @limited = (@demos.size == 51) ? true : false
  end
  
  
  def _after_show
    if @demo
      @navpath = [['Demos', '/demos'], [@demo.demos_category.name, "/demos/buscar?demo[demos_category_id]=#{@demo.demos_category_id}"], [@demo.title, "/demos/#{@demo.demos_category.id}/#{@demo.id}"],]
      @title = @demo.title
    end
  end
  
  def download
    @demo = Demo.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @demo.is_public? 
    @title = @demo.title
    @demo_mirrors = @demo.demo_mirrors
    Demo.increment_counter('downloaded_times', @demo.id)
    CacheObserver.expire_fragment("/common/demos/index/demos_#{@demo.demos_category_id}/page_*") # TODO MUY HEAVY, no podemos hacer que cada demo suponga borrar todas las caches de índices
    CacheObserver.expire_fragment("/common/demos/index/most_demoed_#{@demo.demos_category.root_id}")
    # CacheObserver.expire_fragment("/common/demos/most_demoed_#{@demo.demos_category.root_id}")
    
    render :layout => 'popup'
  end
  
  def create
    require_auth_users
    mirrors = params[:demo][:demo_mirrors].to_s.gsub("\r", "\n").gsub("\n\n", "\n")
    params[:demo][:demo_mirrors] = []
    
    @demo = Demo.new(params[:demo])
    @demo.user_id = @user.id
    @demo.state = Cms::PENDING unless (params[:draft] == '1')
    if Cms.user_can_create_content(@user)
      if @demo.save
        @demo.process_wysiwyg_fields
        result = mirrors.split("\n").each { |s|
          if s.strip != '' then
            opt = DemoMirror.new({:demo_id => @demo.id, :url => s})
            opt.save
          end
        }
        
        flash[:notice] = 'Demo creada correctamente. Tendrá que ser moderada antes de aparecer publicada.'
        if @demo.state == Cms::DRAFT then
          redirect_to :action => 'edit', :id => @demo.id
        else
          redirect_to :action => 'index'
        end
      else
        flash[:error] = "Error al subir el archivo:<br /> #{@demo.errors.full_messages_html}"
        render :action => 'new'
      end
    else
      flash[:error] = "Error al crear la demo: no puedes crear contenidos"
      render :action => 'new'
    end
  end
  
  def edit
    @demo = Demo.find(params[:id])
    # require_user_can_edit(@demo)
    raise ContentLocked if @demo.is_locked_for_user?(@user)
    @title = "Editar #{@demo.title}"
    paths, navpath = @demo.demos_category.get_category_address
    @navpath = navpath + [[@demo.title, "/demos/#{@demo.demos_category.id}/#{@demo.id}"], ['Editar', "/demos/edit/#{@demo.id}"]]
    if Cms::user_can_edit_content?(@user, @demo) then
      @demo.lock(@user)
      render :action => 'edit'
    else
      render :action => 'show'
    end
  end
  
  def update
    @demo = Demo.find(params[:id])
    require_user_can_edit(@demo)
    
    mirrors = params[:demo][:demo_mirrors].to_s.gsub("\r", "\n").gsub("\n\n", "\n")
    params[:demo][:demo_mirrors] = []
    
    @demo.cur_editor = @user
    @demo.state = Cms::PENDING if @demo.state == Cms::DRAFT and not params[:draft].to_s == '1'
    params[:demo][:entity1_local_id] ||= nil
    params[:demo][:entity2_local_id] ||= nil
    
    if @demo.update_attributes(params[:demo])
      @demo.process_wysiwyg_fields
      # actualizamos mirrors
      @demo.demo_mirrors.clear
      
      result = mirrors.split("\n").each { |s|
        s = s.strip
        if s != '' then
          opt = DemoMirror.new({:demo_id => @demo.id, :url => s})
          opt.save
        end
      }
      flash[:notice] = 'Demo actualizada correctamente.'
      if @demo.state == Cms::PENDING && params[:publish_content] == '1'
        Cms::publish_content(@demo, @user)
        flash[:notice] += "\nContenido publicado correctamente. Gracias."
      end
      if @demo.is_public? then
        redirect_to gmurl(@demo)
      else
        redirect_to :action => 'edit', :id => @demo
      end
    else
      flash[:error] = "Error al actualizar la demo: #{@demo.errors.full_messages_html}"
      render :action => 'edit'
    end
  end
  
  def get_games_maps
    raise ActiveRecord::RecordNotFound unless params[:demos_category_id].to_s != ''
    @g = User.db_query("SELECT id FROM games WHERE code = (SELECT code FROM demos_categories WHERE id = #{params[:demos_category_id].to_i})")
    raise ActiveRecord::RecordNotFound unless @g        
    render :layout => false
  end
  
  def get_games_modes
    raise ActiveRecord::RecordNotFound unless params[:demos_category_id].to_s != ''
    @g = User.db_query("SELECT id FROM games WHERE code = (SELECT code FROM demos_categories WHERE id = #{params[:demos_category_id].to_i})")
    raise ActiveRecord::RecordNotFound unless @g
    render :layout => false
  end  
  
  def get_games_versions
    raise ActiveRecord::RecordNotFound unless params[:demos_category_id].to_s != ''
    @g = User.db_query("SELECT id FROM games WHERE code = (SELECT code FROM demos_categories WHERE id = #{params[:demos_category_id].to_i})")
    raise ActiveRecord::RecordNotFound unless @g
    render :layout => false
  end
end
