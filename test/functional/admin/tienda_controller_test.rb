require 'test_helper'

class Admin::TiendaControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :producto ]

  test "producto_work" do
    sym_login 1
    get :producto, :id => 1
    assert_response :success
  end

  test "update_product_work" do
    sym_login 1
    post :update_product, { :id => 1, :product => { :description => 'el nuevo producto del mundo mundial'}}
    assert_response :redirect
    assert_equal 'el nuevo producto del mundo mundial', Product.find(1).description
  end
end
