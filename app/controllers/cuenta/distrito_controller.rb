class Cuenta::DistritoController < ApplicationController
  before_filter :require_user_is_don_or_mano_derecha
  
  def index
  end

  def submenu
    'Distrito'
  end
  
  def submenu_items
    l = [] 
    
    l<<['Staff', '/cuenta/distrito/staff']
    l<<['Categorías de contenidos', '/cuenta/distrito/categorias']
    
    l
  end
  
  def add_sicario
    if params[:login].to_s != ''
      thenew = User.find_by_login(params[:login])
      if thenew.nil?
        flash[:error] = "No se ha encontrado a ningun usuario con el nick <strong>#{params[:login]}</strong>"
        redirect_to '/cuenta/distrito' and return
      end
    end
    @cur_district.add_sicario(thenew)
    flash[:notice] = "Añadido <strong>#{params[:login]}</strong> como sicario de <strong>#{@cur_district.name}</strong>"
    redirect_to '/cuenta/distrito'
  end
  
  def del_sicario
    u = User.find(params[:user_id].to_i)
    @cur_district.del_sicario(u)
    flash[:notice] = "<strong>#{u.login}</strong> ha dejado de ser sicario de <strong>#{@cur_district.name}</strong>"
    redirect_to '/cuenta/distrito'
  end
  
  def update_mano_derecha
    raise AccessDenied if @user_status_in_district != 'Don'
    if params[:login].to_s != ''
      thenew = User.find_by_login(params[:login])
      if thenew.nil?
        flash[:error] = "No se ha encontrado a ningun usuario con el nick <strong>#{params[:login]}</strong>"
        redirect_to '/cuenta/distrito' and return
      end
       (redirect_to '/cuenta/distrito' and return) if @cur_district.mano_derecha && @cur_district.mano_derecha.id == thenew.id 
      if thenew.users_roles.count(:conditions => ['role IN (?)', %w(Don ManoDerecha)]) > 0
        flash[:error] = "<strong>#{thenew.login}</strong> ya es don o mano derecha de otro distrito. Debe dejar su cargo actual antes de poder añadirlo como Mano Derecha de <strong>#{@cur_district.name}</strong>"
        redirect_to '/cuenta/distrito' and return
      end
      flash[:notice] = "Mano Derecha <strong>#{params[:login]}</strong> guardada correctamente"
    else
      thenew = nil
      flash[:notice] = "Mano Derecha eliminada correctamente."
    end
    @cur_district.update_mano_derecha(thenew)
    redirect_to '/cuenta/distrito'
  end
  
  
  # TODO copypaste de cuenta/faccion que a su vez es copypaste de admin
  # TODO aqui se supone que solo pueden llegar dones
  def categorias
    @editable_content_types = []
    if params[:type_name] then
      @tld = @cur_district.top_level_category(Object.const_get(params[:type_name]))
      children_ids = @tld.all_children_ids.collect { |cat| cat.id } + [@tld.id]
      @category_pages, @categories = paginate self.get_cls(params[:type_name]), :conditions => ["parent_id IN (#{children_ids.join(',')}) and id <> ?", @tld.id], :order => 'parent_id desc, lower(name) asc', :per_page => 50
      @title = "Editando categorías #{params[:type_name]}"
      @navpath = [['Cuenta', '/cuenta'], ['Distrito', '/cuenta/distrito'], ['Categorias', '/cuenta/distrito/categorias'], [params[:type_name], "/cuenta/distrito/categorias/#{params[:type_name]}"]]
    else
      @categories = nil
      @title = 'Categorías de contenidos'
      @navpath = [['Cuenta', '/cuenta'], ['Distrito', '/cuenta/distrito']]
    end
    
    for c in ContentType.find(:all, :conditions => 'name in (\'Image\', \'News\', \'Topic\', \'Demo\', \'Download\', \'Review\', \'Tutorial\')')
      @editable_content_types<< c
    end
  end
  
  def categorias_edit
    @tld = @cur_district.top_level_category(Object.const_get(params[:type_name]))
    # Chequeamos los permisos creando un contenido en blanco asociado a la
    # categoría que estamos editando
    @category = self.get_cls(params[:type_name]).find(params[:id])
    @title = "Editando categoría #{params[:type_name]}: #{@category.name}"
    @navpath = [['Cuenta', '/cuenta'], ['Distrito', '/cuenta/distrito'], ['Categorias', '/cuenta/distrito/categorias'], [params[:type_name], "/cuenta/distrito/categorias/#{params[:type_name]}"], [@category.name, "/cuenta/distrito/categorias/#{params[:type_name]}/edit/#{@category.id}"]]
    
    dummy = @category.class.items_class.new({"#{Inflector::underscore(@category.class.name)}_id" => @category.id})
    raise AccessDenied unless Cms::user_can_edit_content?(@user, dummy)
  end
  
  def categorias_destroy
    @category = self.get_cls(params[:type_name]).find(params[:id])
    dummy = @category.class.items_class.new({"#{Inflector::underscore(@category.class.name)}_id" => @category.id})
    raise AccessDenied unless Cms::user_can_edit_content?(@user, dummy)
  end
  
  def categorias_new
    @tld = @cur_district.top_level_category(Object.const_get(params[:type_name]))
    @category = self.get_cls(params[:type_name]).new
    @category = @tld.children.new
    @category.root_id = @tld.id
    dummy = @category.class.items_class.new({"#{Inflector::underscore(@category.class.name)}_id" => @tld.id})
    raise AccessDenied unless Cms::user_can_edit_content?(@user, dummy)
  end
  
  def categorias_update
    @category = self.get_cls(params[:type_name]).find(params[:id])
    @tld = @cur_district.top_level_category(Object.const_get(params[:type_name]))
    dummy = @category.class.items_class.new({"#{Inflector::underscore(@category.class.name)}_id" => @tld.id})
    raise AccessDenied unless Cms::user_can_edit_content?(@user, dummy)
    
    if params[:category][:parent_id].empty? then
      flash[:error] = 'Imposible asignar a categoría en blanco'
      redirect_to "/cuenta/distrito/categorias/#{params[:type_name]}/edit/#{@category.id}"
    else
      if @category.update_attributes(params[:category])
        flash[:notice] = 'Categoría actualizada correctamente.'
        redirect_to "/cuenta/distrito/categorias/#{params[:type_name]}/edit/#{@category.id}"
      else
        flash[:error] = "Error al actualizar la categoría: #{@category.errors.full_messages_html}"
        render :action => 'categorias_edit'
      end
    end
  end
  
  def categorias_create
    @tld = @cur_district.top_level_category(Object.const_get(params[:type_name]))
    @category = self.get_cls(params[:type_name]).new(params[:category])
    @category.root_id = @tld.id
    dummy = @category.class.items_class.new({"#{Inflector::underscore(@category.class.name)}_id" => @tld.id})
    raise AccessDenied unless Cms::user_can_edit_content?(@user, dummy)
    
    if params[:category][:parent_id].empty? then
      flash[:error] = 'Imposible asignar a categoría en blanco'
      redirect_to "/cuenta/distrito/categorias/#{params[:type_name]}/new"
    elsif @category.save
      flash[:notice] = 'Categoría creada correctamente.'
      redirect_to "/cuenta/distrito/categorias/#{params[:type_name]}"
    else
      render :action => 'categorias_new'
    end
  end
  
  def category_destroy_confirm
    @tld = @cur_district.top_level_category(Object.const_get(params[:type_name]))
    # TODO validation
    @category = self.get_cls(params[:type_name]).find(params[:id])
    dummy = @category.class.items_class.new({"#{Inflector::underscore(@category.class.name)}_id" => @tld.id})
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
    
    redirect_to "/cuenta/distrito/categorias/#{params[:type_name]}"
  end
  
  def get_cls(type_name)
    Cms.category_class_from_content_name(type_name)
  end
  
  protected
  def require_user_is_don_or_mano_derecha
    require_auth_users
    ur = @user.users_roles.find(:first, :conditions => ['role IN (?)', %w(Don ManoDerecha)])
    raise AccessDenied unless ur
    @user_status_in_district = ur.role
    @cur_district = BazarDistrict.find(ur.role_data.to_i)
  end
end
