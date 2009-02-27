class Admin::CategoriasController < ApplicationController  
  before_filter :check_permissions
  before_filter :populate_portal_data
  
  private
  def check_permissions
    if portal.respond_to?(:clan_id) && portal.clan_id
      require_auth_clanleader
    else
      require_admin_permission :bazar_manager
    end  
  end
  
  def populate_portal_data
    @cond = (@portal.respond_to?(:clan_id) && @portal.clan_id) ? "clan_id = #{@portal.clan_id}" : nil
  end
  
  public  
  def wmenu_pos
    'hq'
  end
  
  def index
    #if params[:type_name] then
    #  @title = "Categorías de #{params[:type_name]}"
    #  @navpath = [['Admin', '/admin'], ['Categorías de Contenidos', '/admin/categorias'], [params[:type_name], "/admin/categorias/#{params[:type_name]}"]]
    #else
      @title = "Categorías"
      @navpath = [['Admin', '/admin'], ['Categorías de Contenidos', '/admin/categorias']]
    #end
    #@editable_content_types = []
    #if params[:type_name] then
    #  @category_pages, @categories = paginate self.get_cls(params[:type_name]), { :conditions => @cond, :order => 'root_id asc, parent_id desc, lower(name) asc', :per_page => 50}
    #else
      @categories = nil
    #end
    
    #names = (@portal.respond_to?(:clan_id) && @portal.clan_id) ? Cms::CLANS_CONTENTS : Cms::CONTENTS_WITH_CATEGORIES
    #names = names.collect { |name| "'#{name}'" }
    #@editable_content_types = ContentType.find(:all, :conditions => "name in (#{names.join(',')})", :order => 'lower(name) ASC')
  end
  
  def root
    @root_term = Term.single_toplevel(:id => params[:id])
    raise ActiveRecord::RecordNotFound unless @root_term
    @content_types = Term.content_types_from_root(@root_term)
    render :layout => false
  end
  
  
  def hijos
    # TODO permisos
    @term = Term.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @term
  end
  
  def contenidos
    # TODO permisos
    @term = Term.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @term
  end
  
    def update
    # TODO permisos
    @term = Term.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @term
    @term.update_attributes(params[:term])
    redirect_to params[:redirto] ? params[:redirto] : '/admin/categorias' 
  end
  
  def mass_move
    # TODO permisos
    @term = Term.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @term
    dst = Term.find(params[:destination_term_id])
    raise ActiveRecord::RecordNotFound unless dst
    @term.find(:all, :content_type => params[:content_type], :conditions => "contents.id in (#{params[:contents].join(', ')})").each do |c|
      @term.unlink(c.unique_content)
      dst.link(c.unique_content)
    end
    @term.update_attributes(params[:term])
    redirect_to params[:redirto] ? params[:redirto] : '/admin/categorias' 
  end
  
  def destroy
    # TODO permisos
    @term = Term.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @term
    if @term.can_be_destroyed?
    @term.destroy
    flash[:notice] = "Categoría <strong>#{@term.name}(#{@term.taxonomy})</strong> destruída correctamente. Khali se complace."
  else
    flash[:error] = "No se puede eliminar la categoría. Asegúrate de que no tiene subcategorías ni contenidos."
    end
    redirect_to params[:redirto] ? params[:redirto] : '/admin/categorias' 
  end
  
  def create
    @term = Term.new(params[:term])
    if @term.save
      flash[:notice] = 'Categoría creada correctamente.'
    else
      flash[:error] = "Error al crear la categoría: #{@term.errors.full_messages_html}"
    end
    redirect_to params[:redirto] ? params[:redirto] : '/admin/categorias'
  end
  
  
  def categorias_edit
    @category = self.get_cls(params[:type_name]).find(params[:id])
    @title = "Editando categoría de #{params[:type_name]}: #{@category.name}"
    @navpath = [['Admin', '/admin'], ['Categorías de Contenidos', '/admin/categorias'], [params[:type_name], "/admin/categorias/#{params[:type_name]}"], [@category.name, "/admin/categorias/#{params[:type_name]}/edit/#{@category.id}"]]
    @tld = portal.send("#{Inflector::tableize(params[:type_name])}_categories")
  end
  
  def categorias_destroy
    @category = self.get_cls(params[:type_name]).find(params[:id])
  end
  
  def categorias_new
    @tld = portal.send("#{Inflector::tableize(params[:type_name])}_categories")
    @category = self.get_cls(params[:type_name]).new
    @category.root_id = @tld.id
    dummy = @category.class.items_class.new({"#{Inflector::underscore(@category.class.name)}_id" => @tld.id})
  end
  
  def categorias_update
    @category = self.get_cls(params[:type_name]).find(params[:id])
    @tld = portal.send("#{Inflector::tableize(params[:type_name])}_categories")
    dummy = @category.class.items_class.new({"#{Inflector::underscore(@category.class.name)}_id" => @tld.id})
    valid_categories = @tld[0].all_children_ids(@tld[0])
    if @portal.respond_to?(:clan_id) && !valid_categories.include?(params[:category][:parent_id].to_i)
      flash[:error] = 'La categoría padre elegida no es válida.'
      render :action => 'categorias_edit'
    elsif @category.update_attributes(params[:category])
      flash[:notice] = 'Categoría actualizada correctamente.'
      redirect_to "/admin/categorias/#{params[:type_name]}/edit/#{@category.id}"
    else  
      render :action => 'categorias_edit'
    end
  end
  
  def categorias_create
    # TODO permissions
    @tld = portal.send("#{Inflector::tableize(params[:type_name])}_categories")
    @category = self.get_cls(params[:type_name]).new(params[:category])
    @category.root_id = @tld.id
    @category.clan_id = @portal.clan_id if @portal.respond_to? :clan_id
    dummy = @category.class.items_class.new({"#{Inflector::underscore(@category.class.name)}_id" => @tld.id})
    
    valid_categories = @tld[0].all_children_ids(@tld[0])
    if @portal.respond_to?(:clan_id) && !valid_categories.include?(params[:category][:parent_id].to_i)
      flash[:error] = 'La categoría padre elegida no es válida.'
      render :action => 'categorias_new'
    elsif @category.save
      flash[:notice] = 'Categoría creada correctamente.'
      redirect_to "/admin/categorias/#{@category.class.items_class.name}"
    else
      render :action => 'categorias_new'
    end
  end
  
  def category_destroy_confirm
    # TODO validation
    @category = self.get_cls(params[:type_name]).find(params[:id])
    
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
    
    @category.destroy
    flash[:notice] = 'Categoría eliminada correctamente.'
    redirect_to "/admin/categorias/#{params[:type_name]}"
  end
  
  def get_cls(type_name)
    raise "DEPRECATED"
    Cms.category_class_from_content_name(type_name)
  end
end
