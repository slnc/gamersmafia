class Admin::CategoriasController < ApplicationController  
  before_filter :check_permissions
  before_filter :populate_portal_data
  
  private
  def check_permissions
    if portal.respond_to?(:clan_id) && portal.clan_id
      require_auth_clanleader
    else
      require_auth_users
      if params[:id]
        t = Term.find_by_id(params[:id])
        if t && (params[:content_type] || t.taxonomy)
          raise AccessDenied unless Cms::can_admin_term?(user, t, params[:content_type] ? params[:content_type] : ApplicationController.extract_content_name_from_taxonomy(t.taxonomy))
        end
      end
      
      raise AccessDenied unless user.users_roles.count(:conditions => "role IN ('Boss', 'Underboss', 'Don', 'ManoDerecha', 'Sicario', 'Editor')") > 0 || user.has_admin_permission?(:capo)
    end  
  end
  
  def populate_portal_data
    @cond = (@portal.respond_to?(:clan_id) && @portal.clan_id) ? "clan_id = #{@portal.clan_id}" : nil
  end
  
  public  
  def wmenu_pos
    'hq'
  end
  
  
  def cats_path
    'admin/categorias'
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
    render :template => "/admin/categorias/index.rhtml"
  end
  
  def categorias_skip_path
    '../../'
  end
  
  def root
    @root_term = Term.single_toplevel(:id => params[:id])
    raise ActiveRecord::RecordNotFound unless @root_term
    @content_types = Term.content_types_from_root(@root_term)
    render :template => "/admin/categorias/root.rhtml", :layout => false
  end
  
  
  def hijos
    # TODO permisos
    @term = Term.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @term
    render :template => "/admin/categorias/hijos.rhtml"
  end
  
  def contenidos
    # TODO permisos
    @term = Term.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @term
    render :template => "/admin/categorias/contenidos.rhtml"
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
    raise AccessDenied if params[:term][:taxonomy].to_s == ''
    @term = Term.new(params[:term])
    if @term.save
      if !Cms.can_edit_term?(user, @term, ApplicationController.extract_content_name_from_taxonomy(params[:term][:taxonomy]))
        @term.destroy
        raise AccessDenied
      end
      flash[:notice] = 'Categoría creada correctamente.'
    else
      flash[:error] = "Error al crear la categoría: #{@term.errors.full_messages_html}"
    end
    redirect_to params[:redirto] ? params[:redirto] : '/admin/categorias'
  end
end
