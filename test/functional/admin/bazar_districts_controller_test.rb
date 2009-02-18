require File.dirname(__FILE__) + '/../../test_helper'

class Admin::BazarDistrictsControllerTest < ActionController::TestCase
  
  def test_index
    sym_login 1
    get :index
    assert_response :success
  end
  
  def test_create
    sym_login 1
    assert_count_increases(BazarDistrict) do
      post :create, {:bazar_district => {:name => 'el nombrecico', :code => 'el codecico'}}
      assert_redirected_to "/admin/bazar_districts"
    end
  end
  
  def test_edit
    sym_login 1
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_user_with_admin_permission_should_allow_if_registered
    assert_raises(AccessDenied) { get :index }
    u2 = User.find(2)
    sym_login u2
    assert_raises(AccessDenied) { get :index }
    
    u2.give_admin_permission(:bazar_manager)
    
    sym_login u2
    get :index
    assert_response :success
  end
  
  def test_update
    sym_login 1
    u1 = User.find(1)
    u2 = User.find(2)
    post :update, :id => 1, :don => u1.login, :mano_derecha => u2.login
    assert_redirected_to "/admin/bazar_districts/edit/1"
    bd = BazarDistrict.find(1)
    assert_equal 1, bd.don.id
    assert_equal 2, bd.mano_derecha.id
  end
end
