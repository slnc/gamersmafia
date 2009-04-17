require 'test_helper'
require 'cuenta/tienda_controller'

# Re-raise errors caught by the controller.
class Cuenta::TiendaController; def rescue_action(e) raise e end; end

class Cuenta::TiendaControllerTest < ActionController::TestCase


  test_min_acl_level :user, [ :index, :show, :buy ]
  # TODO probar con todos los productos

  def test_should_show_index
    sym_login 1
    get :index
    assert_response :success
  end

  def test_should_show_producto
    sym_login 2 # un usuario sin profile signatures
    prod = Product.find_by_cls('SoldProfileSignatures')
    assert_not_nil prod
    get :show, { :id =>  prod.id }
    assert_response :success
  end

  def test_should_buy_product_if_enough_money
    sym_login 2
    prod = Product.find(:first, :conditions => 'cls = \'SoldChangeNick\' AND price > 0')
    assert_not_nil prod
    u = User.find(2)
    u.add_money(prod.price) # nos aseguramos de que tiene suficiente dinero
    post :buy, { :id => prod.id }
    assert_response :redirect
    @bp = SoldProduct.find(:first, :conditions => ['user_id = ? AND product_id = ?', u.id, prod.id], :order => 'id DESC')
    assert_not_nil @bp
    assert @bp.created_on.to_i > Time.now.to_i - 5
  end
  
  def test_use_should_work
    test_should_buy_product_if_enough_money
    assert !@bp.used?
    post :use, {:id => @bp.id, :nuevo_login => 'fulanitodetal' }
    assert_response :redirect
    @bp.reload
    assert @bp.used?
    
    assert_raises(ActiveRecord::RecordNotFound) { post :use, {:id => @bp.id, :nuevo_login => 'fulanitodetal' } }
  end

  def test_should_not_buy_product_if_insufficient_money
    sym_login 1
    prod = Product.find(:first, :conditions => 'price > 0')
    assert_not_nil prod
    u = User.find(1)
    u.remove_money(u.cash) # nos aseguramos de que no tiene suficiente dinero
    assert_raises(AccessDenied) { post :buy, { :id => prod.id } }
    bp = SoldProduct.find(:first, :conditions => ['user_id = ? AND product_id = ?', u.id, prod.id])
    assert_nil bp
  end

  def test_should_show_mis_compras
    test_should_buy_product_if_enough_money
    get :mis_compras
    assert_response :success
  end

  def test_should_show_configure_page_of_mis_compras
    test_should_buy_product_if_enough_money
    get :configurar_compra, { :id => @bp.id }
    assert_response :success
  end
end
