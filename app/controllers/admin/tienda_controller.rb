class Admin::TiendaController < ApplicationController
  before_filter :require_auth_admins
  
  def index
    
  end
  
  def producto
    # @navbar<< [[@product.name], ["/admin/tienda/producto"]]
    @product = Product.find(params[:id])
    @title = "Editar #{@product.name}"
  end
  
  def update_product
    @product = Product.find(params[:id])
    if @product.update_attributes(params[:product])
      flash[:notice] = "Producto actualizado correctamente"
      redirect_to "/admin/tienda/producto/#{@product.id}"
    else
      flash[:error] = "Error al actualizar el producto: #{@product.errors.full_messages_html}"
    end
  end
end
