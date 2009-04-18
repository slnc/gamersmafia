class Cuenta::SkinsController < ApplicationController
  before_filter :require_auth_users
  
  def submenu
    'skin' if @skin
  end
  
  def submenu_items
    if @skin && @portal.respond_to?(:clan_id) && @portal.clan_id
      [['Cabecera', "/cuenta/skins/cabecera/#{@skin.id}"],
      ['Organización', "/cuenta/skins/organizacion/#{@skin.id}"],
      ['Módulos', "/cuenta/skins/modulos/#{@skin.id}"],
      ['Colores', "/cuenta/skins/colores/#{@skin.id}"],
      ['Texturas', "/cuenta/skins/texturas/#{@skin.id}"],
      ['Otras opciones', "/cuenta/skins/otras_opciones/#{@skin.id}"],
      ]
    else
	    []
    end
  end
  
  def index
    @title = "Mis skins"
  end
  
  def edit
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    @title = "Editar skin #{@skin.name}"
    if @skin.config[:general][:intelliskin] then
      render :action => 'edit_intelliskin'
    else
      render :action => 'edit'
    end    
  end
  
  def create
    raise ActiveRecord::RecordNotFound unless %w(FactionsSkin ClansSkin).include?(params[:skin][:type])
    @skin = Object.const_get(params[:skin][:type]).new(params[:skin].merge({:user_id => @user.id}))
    if @skin.save 
      flash[:notice] = "Skin #{@skin.name} creada correctamente."
    else
      flash[:error] = "Ocurrió un error al crear la skin: #{@skin.errors.full_messages_html}"
    end
    redirect_to :action => :index
  end
  
  def update
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    
    @skin.update_favicon(params[:favicon]) if params[:favicon].to_s != ''      
    
    if (!params[:skin][:intelliskin].nil?)
      @skin.config[:intelliskin] ||= {}
      @skin.config[:intelliskin].merge!(params[:skin][:intelliskin])
      @skin.save_config
      if @skin.update_attributes(params[:skin].pass_sym(:intelliskin_header, :favicon))
        flash[:notice] = "Skin #{@skin.name} actualizada correctamente"
      end
    elsif @skin.update_attributes(params[:skin])
      flash[:notice] = "Skin #{@skin.name} actualizada correctamente."
    else
      flash[:error] = "Ocurrió un error al actualizar la skin: #{@skin.errors.full_messages_html}"
    end
    redirect_to :action => :edit, :id => @skin.id
  end
  
  def destroy
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    @skin.destroy
    flash[:notice] = "Skin #{@skin.name} borrada correctamente."
    redirect_to :action => :index
  end
  
  def cabecera
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    @title = "Cabecera de skin #{@skin.name}"
  end
  
  def organizacion
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    @title = "Organización de skin #{@skin.name}"
  end
  
  def modulos
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    @title = "Módulos de skin #{@skin.name}"
  end
  
  def colores
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    @title = "Colores de skin #{@skin.name}"
  end
  
  def texturas
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    @title = "Texturas de skin #{@skin.name}"
  end
  
  def otras_opciones
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    @title = "Otras opciones de skin #{@skin.name}"
  end
  
  def do_modulos
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    @skin.config[:intelliskin] ||= {}
    @skin.config[:intelliskin][:modules_left] = params[:skin][:intelliskin][:modules_left] || {}
    @skin.config[:intelliskin][:modules_right] = params[:skin][:intelliskin][:modules_right] || {}
    @skin.save_config
    flash[:notice] = "Skin #{@skin.name} actualizada correctamente"
    redirect_to "/cuenta/skins/modulos/#{@skin.id}"
  end
  
  def do_organizacion
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    @skin.config[:intelliskin] ||= {}
    @skin.config[:intelliskin].merge!(params[:skin][:intelliskin])
    @skin.save_config
    flash[:notice] = "Skin #{@skin.name} actualizada correctamente"
    redirect_to "/cuenta/skins/organizacion/#{@skin.id}"
  end
  
  def do_colores
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    @skin.config[:intelliskin] ||= {}
    @skin.config[:intelliskin].merge!(params[:skin][:intelliskin])
    @skin.save_config
    flash[:notice] = "Skin #{@skin.name} actualizada correctamente"
    redirect_to "/cuenta/skins/colores/#{@skin.id}"
  end
  
  def do_cabecera
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    params[:skin][:intelliskin][:header_height] = '224' if params[:skin][:intelliskin][:header_height] && params[:skin][:intelliskin][:header_height].to_i > 224
    params[:skin][:intelliskin][:header_height] = '65' if params[:skin][:intelliskin][:header_height] && params[:skin][:intelliskin][:header_height].to_i < 65
    @skin.config[:intelliskin] ||= {}
    @skin.config[:intelliskin].merge!(params[:skin][:intelliskin])
    @skin.save_config
    if @skin.update_attributes(params[:skin].pass_sym(:intelliskin_header))
      flash[:notice] = "Skin #{@skin.name} actualizada correctamente"
    else
      flash[:error] = "Error al actualizar la página"
    end
    
    redirect_to "/cuenta/skins/cabecera/#{@skin.id}"
  end
  
  def do_otras_opciones
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])
    if @skin.update_attributes(params[:skin].pass_sym(:intelliskin_favicon))
      flash[:notice] = "Skin #{@skin.name} actualizada correctamente"
    else
      flash[:error] = "Error al actualizar la página"
    end
    
    redirect_to "/cuenta/skins/otras_opciones/#{@skin.id}"
  end
  
  def texturas_por_tipo
    if Skins::TexturesGenerators.texturable_things.include?(params[:id])
      @textures = Texture.find(:all, :conditions => "valid_element_selectors = '''all''' or valid_element_selectors LIKE '%''#{params[:id]}''%'")
    else
      @textures = []
    end
    render :layout => false
  end
  
  def config_textura
    @texture = Texture.find_by_name(params[:id])
    # TODO esto porque sabemos que es en config de la skin actual (unicamente)
    raise ActiveRecord::RecordNotFoud unless @texture
    @sk = SkinTexture.new({:skin_id => skin.id, :texture_id => @texture.id})
    @sk.send :check_user_config
    #@sk.initialize_user_config
    render :layout => false
  end
  
  def do_create_textura
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:skin_texture][:skin_id], @user.id])
    @texture = Texture.find(params[:skin_texture][:texture_id])
    # TODO chequear que ele elemnt es v:alido no?
    params[:skin_texture][:element] = "'#{params[:skin_texture][:element]}'"
    @sk = SkinTexture.new(params[:skin_texture])
    if @sk.save
      flash[:warning] = "Textura creada correctamente"
      @skin.save_config
    else
      flash[:error] = "Error al crear la textura: #{@sk.errors.full_messages_html}"
    end
    
    redirect_to "/cuenta/skins/texturas/#{@skin.id}"
  end
  
  def skin_textura
    @sk = skin.skin_textures.find_by_id(params[:id])
    raise ActiveRecord::RecordNotFound unless @sk
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', @sk.skin_id, @user.id])
  end
  
  def update_skin_texture
    sk = skin.skin_textures.find_by_id(params[:id])
    raise ActiveRecord::RecordNotFound unless sk
    skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', sk.skin_id, @user.id])
    raise ActiveRecord::RecordNotFound unless skin
    
    if sk.update_attributes(params[:skin_texture])
      flash[:notice] = "Textura actualizada correctamente"
      skin.save_config
    else
      flash[:error] = "Error al crear la textura: #{sk.errors.full_messages_html}"
    end
    
    redirect_to "/cuenta/skins/texturas/#{skin.id}"
  end
  
  def borrar_skin_textura
    sk = skin.skin_textures.find_by_id(params[:id])
    raise ActiveRecord::RecordNotFound unless sk
    skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', sk.skin_id, @user.id])
    raise ActiveRecord::RecordNotFound unless skin
    skin.remove_skin_texture(sk)
    redirect_to "/cuenta/skins/texturas/#{skin.id}"
  end


  def activate
    @skin = Skin.find_or_404(:first, :conditions => ['id = ? AND user_id = ?', params[:skin], @user.id])
    cookies[:skin] = @skin.id
    flash[:notice] = "Skin #{@skin.name} activada correctamente"
    redirect_to "/cuenta/skins"
  end
end
