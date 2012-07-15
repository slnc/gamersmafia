# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::BazarDistrictsControllerTest < ActionController::TestCase

  test "index" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "create" do
    sym_login 1
    assert_count_increases(BazarDistrict) do
      post :create, {:bazar_district => {:name => 'el nombrecico', :code => 'codecico'}}
      assert_redirected_to "/admin/bazar_districts"
    end
  end

  test "edit" do
    sym_login 1
    get :edit, :id => 1
    assert_response :success
  end

  test "user_with_admin_permission_should_allow_if_registered" do
    assert_raises(AccessDenied) { get :index }
    u2 = User.find(2)
    sym_login u2
    assert_raises(AccessDenied) { get :index }

    u2.give_admin_permission(:bazar_manager)

    sym_login u2
    get :index
    assert_response :success
  end

  test "update" do
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
