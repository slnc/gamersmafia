class Cuenta::TiendaController < ApplicationController
  before_filter :require_auth_users

  def index
  end

  def show
    @product = Product.find(params[:id])
    @title = @product.name
  end

  def buy
    @product = Product.find(:first, :conditions => ['id = ? and enabled=\'t\'', params[:id]])
    sp = Shop.buy(@product, @user)
    flash[:notice] = sp.used? ? 'Producto comprado y consumido correctamente' : 'Producto comprado correctamente. Debes configurarlo para poder consumirlo.'
    redirect_to sp.used? ? '/cuenta/tienda' : "/cuenta/mis_compras/#{sp.id}"
  end

  def mis_compras
  end

  def configurar_compra
    @sold_product = @user.sold_products.find(params[:id])
    @title = @sold_product.product.name
  end

  def use
    @sold_product = @user.sold_products.find(params[:id])
    # @sold_product = SoldProduct.find(@sold_product.id)
    raise ActiveRecord::RecordNotFound if @sold_product.used?

    if @sold_product.use(params)
      flash[:notice] = 'Producto consumido correctamente'
    else
      flash[:error] = "Ocurrió un error al intentar consumir el producto:<br />#{@sold_product.errors.full_messages_html}"
    end

    redirect_to :action => :mis_compras
  end
end
