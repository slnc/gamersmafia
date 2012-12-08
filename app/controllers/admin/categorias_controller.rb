# -*- encoding : utf-8 -*-
class Admin::CategoriasController < ApplicationController
  before_filter :check_permissions

  private
  def check_permissions
    require_auth_users
    if params[:id]
      t = Term.find_by_id(params[:id])
      if t && (params[:content_type] || t.taxonomy)
        raise AccessDenied unless Authorization.can_edit_term?(
            user,
            t,
            params[:content_type] ? params[:content_type] :
            Cms.extract_content_name_from_taxonomy(t.taxonomy))
      end
    end

    raise AccessDenied unless Authorization.can_admin_non_root_terms?(@user)
  end

  public
  def cats_path
    'admin/categorias'
  end

  def index
    @title = "Categorías"
    @navpath = [
        ['Admin', '/admin'],
        ['Categorías de Contenidos', '/admin/categorias']]
    @categories = nil
    render :template => "/admin/categorias/index"
  end

  def categorias_skip_path
    '../../'
  end

  def root
    @root_term = Term.single_toplevel(:id => params[:id])
    raise ActiveRecord::RecordNotFound unless @root_term
    @content_types = Term.content_types_from_root(@root_term)
    render :template => "/admin/categorias/root", :layout => false
  end


  def hijos
    # TODO permisos
    @term = Term.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @term
    render :template => "/admin/categorias/hijos"
  end

  def contenidos
    # TODO permisos
    @term = Term.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @term
    render :template => "/admin/categorias/contenidos"
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
    dst = Term.find(params[:destination_term_id])
    Content.in_term(@term).content_type_name(params[:content_type]).find(
        :all,
        :conditions => "id in (#{params[:contents].join(', ')})").each do |c|
      @term.unlink(c)
      dst.link(c)
    end
    @term.update_attributes(params[:term]) # TODO why?
    redirect_to params[:redirto] ? params[:redirto] : '/admin/categorias'
  end

  def destroy
    # TODO permisos
    @term = Term.find(params[:id])

    if @term.can_be_destroyed?
      @term.destroy
      flash[:notice] = "Categoría "+
                       "<strong>#{@term.name}(#{@term.taxonomy})</strong> "+
                       "destruída correctamente. Khali se complace."
    else
      flash[:error] = "No se puede eliminar la categoría. "+
                      "Asegúrate de que no tiene subcategorías ni contenidos."
    end
    redirect_to params[:redirto] ? params[:redirto] : '/admin/categorias'
  end

  def create
    raise AccessDenied if params[:term][:taxonomy].to_s == ''
    @term = Term.new(params[:term])
    if @term.save
      if !Authorization.can_create_term?(
          user,
          @term,
          Cms.extract_content_name_from_taxonomy(params[:term][:taxonomy]))
        @term.destroy
        raise AccessDenied
      end
      flash[:notice] = 'Categoría creada correctamente.'
    else
      flash[:error] = "Error al crear la categoría: "+
                      "#{@term.errors.full_messages_html}"
    end
    redirect_to params[:redirto] ? params[:redirto] : '/admin/categorias'
  end
end
