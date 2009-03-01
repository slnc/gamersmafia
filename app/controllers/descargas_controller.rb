class DescargasController < InformacionController
  acts_as_content_browser :download
  allowed_portals [:gm, :faction, :clan, :bazar_district]
  
  def index
    @title = 'Descargas'
    
    parent_id = params[:category]
    if parent_id then
      # TODO BUG no estamos chequeando que la categoría se pueda ver desde aquí 
      @category = Term.find_taxonomy(parent_id, 'DownloadsCategory')
      @category = Term.find_taxonomy(parent_id, nil) if @category.nil?
      raise ActiveRecord::RecordNotFound if @category.nil?
      paths, @navpath = get_category_address(@category, 'DownloadsCategory')
      @title = paths.join(' &raquo; ')
    end
  end
  
  def _after_show
    if @download
      paths, navpath = get_category_address(@download.main_category, 'DownloadsCategory')
      @navpath = navpath + [[@download.title, "/descargas/#{@download.main_category.id}/#{@download.id}"],]
      @title = @download.title
    end
  end
  
  def download
    @download = Download.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @download.is_public?
      
    @title = @download.title
    @download_mirrors = @download.download_mirrors
    Download.increment_counter('downloaded_times', @download.id)
    dd = @download.downloaded_downloads.create(:user_id => (user_is_authed ? @user.id : nil), :session_id => session[:session_id], :ip => request.remote_ip, :referer => request.env['HTTP_REFERER'].to_s)
    # TODO PERF no borrar las caches con tanta gracia, ¿no?
    CacheObserver.expire_fragment("/common/descargas/index/downloads_#{@download.main_category.id}/page_*") # TODO MUY HEAVY, no podemos hacer que cada descarga suponga borrar todas las caches de índices
    CacheObserver.expire_fragment("/common/descargas/index/most_downloaded_#{@download.main_category.root_id}")
    if params[:r]
      @download_link = params[:r]
    else
      # CacheObserver.expire_fragment("/common/descargas/most_downloaded_#{@download.main_category.root_id}")
	gm_link = @download.created_on > 1.day.ago ? 0 : 1
# TODO temp
#gm_link = nil
      final_mirror = Download.create_symlink(dd.download_cookie, @download.file, gm_link)  # 1 = NLS
      final_mirror = 0 if final_mirror.nil?
      end_file = @download.file.gsub("#{RAILS_ROOT}/public/storage", '')
      @download_link = "#{Download::MIRRORS_DOWNLOAD[final_mirror]}d/#{dd.download_cookie}/#{File.basename(end_file)}" 
    end
    render :layout => 'blank'
  end
  
  def dauth
    raise ActiveRecord::RecordNotFound unless params[:gmk] && params[:ddc] && params[:f]
    raise AccessDenied unless params[:gmk] == App.mirror_auth_key
    Download.create_symlink(params[:ddc], params[:f])
    render :nothing => true
  end
  
  def create_from_zip
    require_auth_users
    raise ActiveRecord::RecordNotFound unless Cms::user_can_mass_upload(@user)
    newfile = params[:download][:file]
    tmp_dir = "#{Dir.tmpdir}/#{Kernel.rand.to_s}"
    # descomprimimos
    if not newfile.path then
      File.open("#{tmp_dir}.zip", 'w+') do |f|
        f.write(newfile.read())
      end
      path = "#{tmp_dir}.zip"
    else
      path = newfile.path
    end
    
    system ("unzip -q -j #{path} -d #{tmp_dir}")
    # añadimos imgs al dir del usuario
    i = 0
    for f in (Dir.entries(tmp_dir) - %w(.. .))
      download = Download.new
      File.open("#{tmp_dir}/#{f}") do |ff|
        download.file = ff
        download.user_id = @user.id
        if @portal.respond_to?(:clan_id) && @portal.clan_id
          download.clan_id = @portal.clan_id
          download.state = Cms::PUBLISHED
        end
        
        download.title = f.bare
        download.terms = params[:download][:terms] # TODO permissions
        i += 1 if download.save
      end
    end
    
    # limpiamos
    system("rm -r #{tmp_dir}")
    flash[:notice] = "#{i} descargas subidas correctamente. Tendrán que ser moderadas antes de aparecer publicada."
    redirect_to :action => ''
  end
  
  
  def create
    require_auth_users
    mirrors = params[:download]['download_mirrors'].to_s.gsub("\r", "\n").gsub("\n\n", "\n")
    params[:download]['download_mirrors'] = []
    @download = Download.new(params[:download])
    @download.user_id = @user.id
    
    if @portal.respond_to?(:clan_id) && @portal.clan_id
      @download.clan_id = @portal.clan_id
      @download.state = Cms::PUBLISHED
    else
      @download.state = Cms::PENDING unless (params[:draft] == '1')
    end
    if Cms.user_can_create_content(@user)
      if @download.save
        @download.process_wysiwyg_fields
        result = mirrors.split("\n").each { |s|
          if s.strip != '' then
            opt = DownloadMirror.new({:download_id => @download.id, :url => s})
            opt.save
          end
        }
        
        flash[:notice] = 'Descarga creada correctamente. Tendrá que ser moderada antes de aparecer publicada.'
        if @download.state == Cms::DRAFT then
          redirect_to :action => 'edit', :id => @download.id
        else
          redirect_to :action => 'index'
        end
      else
        flash[:error] = "Error al subir el archivo:<br /> #{@download.errors.full_messages_html}"
        render :action => 'new'
      end
    else
      flash[:error] = "Error al crear la descarga: no puedes crear contenidos"
      render :action => 'new'
    end
  end
  
  def edit
    @download = Download.find(params[:id])
    # require_user_can_edit(@download)
    raise ContentLocked if @download.is_locked_for_user?(@user)
    @title = "Editar #{@download.title}"
    # paths, navpath = get_category_address(@download.main_category, 'DownloadsCategory')
    @navpath = []
    @navpath << [@download.title, "/descargas/#{@download.main_category.id}/#{@download.id}"] if @download.main_category
    @navpath << ['Editar', "/descargas/edit/#{@download.id}"]
    if Cms::user_can_edit_content?(@user, @download) then
      @download.lock(@user)
      render :action => 'edit'
    else
      render :action => 'show'
    end
  end
  
  def update
    @download = Download.find(params[:id])
    require_user_can_edit(@download)
    params[:download][:download_mirrors] = [] unless params[:download][:download_mirrors]
    mirrors = params[:download][:download_mirrors].to_s.gsub("\r", "\n").gsub("\n\n", "\n")
    params[:download][:download_mirrors] = []
    
    @download.cur_editor = @user
    @download.state = Cms::PENDING if @download.state == Cms::DRAFT and not params[:draft].to_s == '1'
    @download.file = params[:download][:file] if params[:download][:file] 
    if @download.update_attributes(params[:download])
      @download.process_wysiwyg_fields
      # actualizamos mirrors
      @download.download_mirrors.each { |m| m.destroy }
      
      result = mirrors.split("\n").each { |s|
        s = s.strip
        if s != '' then
          opt = DownloadMirror.new({:download_id => @download.id, :url => s})
          opt.save
        end
      }
      flash[:notice] = 'Descarga actualizada correctamente.'
      if @download.state == Cms::PENDING && params[:publish_content] == '1'
        Cms::publish_content(@download, @user)
        flash[:notice] += "\nContenido publicado correctamente. Gracias."
      end
      if @download.is_public? then
        redirect_to gmurl(@download)
      else
        redirect_to :action => 'edit', :id => @download
      end
    else
      render :action => 'edit'
    end
  end
end
