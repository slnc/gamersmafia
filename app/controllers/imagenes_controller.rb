class ImagenesController < BazarController
  acts_as_content_browser :image
  allowed_portals [:gm, :faction, :clan, :bazar, :bazar_district]
  
  def category
    @category = Term.find_taxonomy(params[:category], 'ImagesCategory')
    @title = @category.name
    if not @category.parent_id then
      @navpath = [['Imágenes', '/imagenes'], [@category.name, "/imagenes/#{@category.id}"]]
      render :action => 'toplevel'
    else
      @navpath = [['Imágenes', '/imagenes'], [@category.parent.name, "/imagenes/#{@category.parent.id}"], [@category.name, "/imagenes/#{@category.id}"]]
      render :action => 'gallery'
    end
  end
  
  def index
    @categories = portal.categories(Image)
    if @categories.size == 1
      @navpath = [['Imágenes', '/imagenes'], ]
      @category = @categories[0]
      render :action => 'toplevel'
    else
      @title = "Imágenes"
      @navpath = [['Imágenes', '/imagenes'], ]
      render :action => 'index'
    end
  end
  
  def toplevel
  end
  
  def potds
    @title = 'Imágenes del día'
  end
  
  def gallery
  end
  
  def _after_show
    if @image # podemos estar haciendo 301
      if @image.main_category.parent then
        @title = "#{@image.main_category.parent.name} &raquo; #{@image.main_category.name} &raquo; Imagen #{File.basename(@image.file) if @image.file}"
        @navpath = [['Imágenes', '/imagenes'], [@image.main_category.parent.name, "/imagenes/#{@image.main_category.parent.id}"], [@image.main_category.name, "/imagenes/#{@image.main_category.id}"], [File.basename(@image.file), gmurl(@image)]]
      else
        @title = "#{@image.main_category.name} &raquo; Imagen #{@image.file ? File.basename(@image.file) : ''}"
        @navpath = [['Imágenes', '/imagenes'], [@image.main_category.name, "/imagenes/#{@image.main_category.id}"], [@image.file ? File.basename(@image.file) : 'Imagen', gmurl(@image)]]
      end
    end
  end
  
  def create_from_zip
    require_auth_users
    raise ActiveRecord::RecordNotFound unless Cms::user_can_mass_upload(@user)
    @category = Term.find_taxonomy(params[:image][:images_category_id], 'ImagesCategory')
    
    if @category.parent_id.nil? then
      flash[:error] = 'Debes elegir una subcategoría, no una categoría'
      new
      render :action => 'new'
    elsif !params[:image][:file].respond_to?(:path)
      flash[:error] = 'Debes elegir un archivo zip que contenga imágenes'
      new
      render :action => 'new'
    else
      newfile = params[:image][:file]
      tmp_dir = "#{Dir.tmpdir}/#{Kernel.rand.to_s}"
      # descomprimimos
      if not newfile.path then # TODO comprobar que StringIO tiene path y no se mete en el elsif anterior
        File.open("#{tmp_dir}.zip", 'w+') { |f| f.write(newfile.read()) }
        path = "#{tmp_dir}.zip"
      else
        path = newfile.path
      end
      
      system("unzip -q -j #{path} -d #{tmp_dir}")
      # añadimos imgs al dir del usuario
      i = 0
      for f in (Dir.entries(tmp_dir) - %w(.. .))
        im = Image.new
        File.open("#{tmp_dir}/#{f}") do |ff|
          im.file = ff
          im.state = Cms::PENDING
          im.description = ''
          im.user_id = @user.id
          if @portal.respond_to?(:clan_id) && @portal.clan_id
            im.clan_id = @portal.clan_id
            im.state = Cms::PUBLISHED
          end
          im.images_category_id = params[:image][:images_category_id] # TODO permissions
          i += 1 if im.save
        end
      end
      
      # limpiamos
      system("rm -r #{tmp_dir}")
      flash[:notice] = "#{i} imágenes subidas correctamente. Tendrán que ser moderadas antes de aparecer publicada."
      redirect_to '/imagenes'
    end
  end
  
  def create
    require_auth_users
    @image = Image.new(params[:image])
    @image.user_id = @user.id
    
    if @portal.respond_to?(:clan_id) && @portal.clan_id
      @image.clan_id = @portal.clan_id
      @image.state = Cms::PUBLISHED
    else
      @image.state = Cms::PENDING unless (params[:draft] == '1')
    end
    
    if !Cms.user_can_create_content(@user)
      flash[:error] = "Error al crear imagen: No puedes crear contenidos."
      render :action => 'new'
    elsif @image.main_category.nil? or @image.main_category.parent_id.nil? then
      flash[:error] = 'Debes elegir una subcategoría, no una categoría'
      render :action => 'new'
    else
      if @image.save
        @image.process_wysiwyg_fields
        flash[:notice] = 'Imagen subida correctamente. Tendrá que ser moderada antes de aparecer publicada.'
        if @image.state == Cms::DRAFT then
          redirect_to :action => 'edit', :id => @image.id
        else
          redirect_to :action => 'index'
        end
      else
        flash[:error] = "Error al subir la imagen:<br /> #{@image.errors.full_messages_html}"
        @pending = Image.pending
        render :action => 'new'
      end
    end
  end
end
