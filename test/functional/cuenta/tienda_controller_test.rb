require 'test_helper'

class Cuenta::TiendaControllerTest < ActionController::TestCase


  test_min_acl_level :user, [ :index, :show, :buy ]
  # TODO probar con todos los productos

  test "should_show_index" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "should_show_producto" do
    sym_login 2 # un usuario sin profile signatures
    prod = Product.find_by_cls('SoldProfileSignatures')
    assert_not_nil prod
    get :show, { :id =>  prod.id }
    assert_response :success
  end

  test "should_buy_product_if_enough_money" do
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
  
  test "use_should_work" do
    test_should_buy_product_if_enough_money
    assert !@bp.used?
    post :use, {:id => @bp.id, :nuevo_login => 'fulanitodetal' }
    assert_response :redirect
    @bp.reload
    assert @bp.used?
    
    assert_raises(ActiveRecord::RecordNotFound) { post :use, {:id => @bp.id, :nuevo_login => 'fulanitodetal' } }
  end

  test "should_not_buy_product_if_insufficient_money" do
    sym_login 1
    prod = Product.find(:first, :conditions => 'price > 0')
    assert_not_nil prod
    u = User.find(1)
    u.remove_money(u.cash) # nos aseguramos de que no tiene suficiente dinero
    assert_raises(AccessDenied) { post :buy, { :id => prod.id } }
    bp = SoldProduct.find(:first, :conditions => ['user_id = ? AND product_id = ?', u.id, prod.id])
    assert_nil bp
  end

  test "should_show_mis_compras" do
    test_should_buy_product_if_enough_money
    get :mis_compras
    assert_response :success
  end

  test "should_show_configure_page_of_mis_compras" do
    test_should_buy_product_if_enough_money
    get :configurar_compra, { :id => @bp.id }
    assert_response :success
  end
end
