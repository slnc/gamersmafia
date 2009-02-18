class Admin::CategoriasfaqController < ApplicationController
  require_admin_permission :faq
  
  def index
    @faq_categories = FaqCategory.find(:all, :conditions => 'parent_id is null', :order => 'position asc, root_id asc, parent_id desc, lower(name) asc')
  end
  
  def new
    @title = "Nueva categoría de FAQ"
    @faq_category = FaqCategory.new
  end
  
  def create
    @faq_category = FaqCategory.new(params[:faq_category])
    if @faq_category.save
      flash[:notice] = 'Categoría FAQ creada correctamente.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end
  
  def edit
    @faq_category = FaqCategory.find(params[:id])
    @title = "Editar categoría de FAQ: #{@faq_category.name}"
  end
  
  def update
    @faq_category = FaqCategory.find(params[:id])
    if @faq_category.update_attributes(params[:faq_category])
      flash[:notice] = 'Categoría FAQ actualizada correctamente.'
      redirect_to :action => 'edit', :id => @faq_category
    else
      render :action => 'edit'
    end
  end
  
  def moveup
    @faq_category = FaqCategory.find(params[:id])
    @prev = FaqCategory.find(:first, :conditions => ['position < ?', @faq_category.position], :order => 'position DESC', :limit => 1)
    if @prev
      tmp = @prev.position
      @prev.position = @faq_category.position
      @faq_category.position = tmp
      @prev.save
      @faq_category.save
      flash[:notice] = 'Categoría FAQ actualizada correctamente.'
    else
      flash[:error] = 'Error al mover la categoría'
    end
    redirect_to :action => 'index'
  end
  
  def movedown
    @faq_category = FaqCategory.find(params[:id])
    @prev = FaqCategory.find(:first, :conditions => ['position > ?', @faq_category.position], :order => 'position ASC', :limit => 1)
    if @prev
      tmp = @prev.position
      @prev.position = @faq_category.position
      @faq_category.position = tmp
      @prev.save
      @faq_category.save
      flash[:notice] = 'Categoría FAQ actualizada correctamente.'
    else
      flash[:error] = 'Error al mover la categoría'
    end
    redirect_to :action => 'index'
  end
  
  def destroy
    if FaqCategory.find(params[:id]).destroy
      flash[:notice] = "Categoría de FAQ borrada correctamente."
    else
      flash[:error] = "Error al borrar categoría de FAQ."
    end
    redirect_to :action => 'index'
  end
end
