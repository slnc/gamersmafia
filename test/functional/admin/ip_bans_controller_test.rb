require 'test_helper'

class Admin::IpBansControllerTest < ActionController::TestCase
  test "index" do
    sym_login 1
    get :index
    assert_response :success
  end
  
  test "create" do
    sym_login 1
    assert_count_increases(IpBan) do
      post :create, {:ip_ban => {:ip => '192.168.0.10'}}
      assert_response :redirect
    end
    
  end
  
  test "destroy" do
    test_create
    assert_count_decreases(IpBan) do
      post :destroy, {:id => IpBan.find(:first)}
      assert_response :redirect
    end
  end
  
  test "user_with_admin_permission_should_allow_if_registered" do
    assert_raises(AccessDenied) { get :index }
    u2 = User.find(2)
    sym_login u2
    assert_raises(AccessDenied) { get :index }
    
    u2.give_admin_permission(:capo)
    
    sym_login u2
    get :index
    assert_response :success
  end
end
