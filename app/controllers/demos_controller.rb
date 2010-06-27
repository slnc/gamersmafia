class DemosController < ArenaController
  acts_as_content_browser :demo
  allowed_portals [:gm, :faction, :clan, :arena]
  
  def index
    @title = 'Demos'
  end
  
  def buscar
    redirect_to :action => 'index' and return false unless params[:demo_term_id] #.kind_of? Hash)
    @title = 'Resultados de la búsqueda'
    sql_conds = []
    if params[:demo]
    %w(demotype pov_type games_mode_id event_id games_version_id games_map_id entity1_local_id entity2_local_id).each do |attr|
      next unless params[:demo] && params[:demo][attr.to_sym].to_s != ''
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
    end
    sql_conds<< ['1 = 1']
    @demos = portal.demo.find(:published, :conditions => sql_conds.join(' AND '), :limit => 51, :order => 'created_on')
    @limited = (@demos.size == 51) ? true : false
  end
  
  
  def _after_show
    if @demo
      @navpath = [['Demos', '/demos'], [@demo.main_category.name, "/demos/buscar?demo_term_id=#{@demo.main_category.id}"], [@demo.title, "/demos/#{@demo.main_category.id}/#{@demo.id}"],]
      @title = @demo.title
    end
  end
  
  def download
    @demo = Demo.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @demo.is_public?
      
    @title = @demo.title
    @demo_mirrors = @demo.demo_mirrors
    Demo.increment_counter('downloaded_times', @demo.id)
    #dd = @demo.downloaded_demos.create(:user_id => (user_is_authed ? @user.id : nil), :session_id => session[:session_id], :ip => request.remote_ip, :referer => request.env['HTTP_REFERER'].to_s)
    # TODO PERF no borrar las caches con tanta gracia, ¿no?
    CacheObserver.expire_fragment("/common/demos/index/downloads_#{@demo.main_category.id}/page_*") # TODO MUY HEAVY, no podemos hacer que cada descarga suponga borrar todas las caches de índices
    CacheObserver.expire_fragment("/common/demos/index/most_demoed_#{@demo.main_category.root_id}")
    if params[:r] 
        #if Cms::URL_REGEXP_FULL =~ params[:r] #DemoMirror.find_by_url(URI::unescape(params[:r]))
          @demo_link = params[:r]
        #lse
        # flash[:error] = "URL de descarga inválida"
        # redirect_to "/descargas/show/#{@demo.id}"
        #nd
    else
      # CacheObserver.expire_fragment("/common/descargas/most_downloaded_#{@demo.main_category.root_id}")
	gm_link = @demo.created_on > 1.day.ago ? 0 : 1
# TODO temp
#gm_link = nil
      final_mirror = nil # Demo.create_symlink(dd.download_cookie, @demo.file, gm_link)  # 1 = NLS
      final_mirror = 0 if final_mirror.nil?
      end_file = @demo.file.to_s.gsub("#{RAILS_ROOT}/public/storage", '')
      @demo_link = @demo.file.to_s # "#{Download::MIRRORS_DOWNLOAD[final_mirror]}d/#{dd.download_cookie}/#{File.basename(end_file)}" 
    end
    render :layout => 'blank'
  end
  
  def edit
    @demo = Demo.find(params[:id])
    # require_user_can_edit(@demo)
    raise ContentLocked if @demo.is_locked_for_user?(@user)
    @title = "Editar #{@demo.title}"
    paths, navpath = get_category_address(@demo.main_category, 'DemosCategory')
    @navpath = navpath + [[@demo.title, "/demos/#{@demo.main_category.id}/#{@demo.id}"], ['Editar', "/demos/edit/#{@demo.id}"]]
    if Cms::user_can_edit_content?(@user, @demo) then
      @demo.lock(@user)
      render :action => 'edit'
    else
      render :action => 'show'
    end
  end
  
  def get_games_maps
    raise ActiveRecord::RecordNotFound unless params[:game_id].to_s != ''
    @g = Game.find(params[:game_id])
    raise ActiveRecord::RecordNotFound unless @g        
    render :layout => false
  end
  
  def get_games_modes
    raise ActiveRecord::RecordNotFound unless params[:game_id].to_s != ''
    @g = Game.find(params[:game_id])
    raise ActiveRecord::RecordNotFound unless @g
    render :layout => false
  end  
  
  def get_games_versions
    raise ActiveRecord::RecordNotFound unless params[:game_id].to_s != ''
    @g = Game.find(params[:game_id])
    raise ActiveRecord::RecordNotFound unless @g
    render :layout => false
  end
end
