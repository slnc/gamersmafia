# -*- encoding : utf-8 -*-
require 'test_helper'

class Cuenta::DistritoControllerTest < ActionController::TestCase

  test "should_work_if_don_or_mano_derecha" do
    u2 = User.find(2)
    assert_raises(AccessDenied) { get :index }
    sym_login 2
    assert_raises(AccessDenied) { get :index }
    @bd = BazarDistrict.find(:first)
    @bd.update_don(u2)
    get :index
    assert_response :success
  end

  test "should_update_mano_derecha" do
    test_should_work_if_don_or_mano_derecha
    post :update_mano_derecha, :login => 'MrMan'
    assert_response :redirect
    @bd.reload
    assert_equal 'MrMan', @bd.mano_derecha.login
  end

  test "should_add_sicario" do
    test_should_work_if_don_or_mano_derecha
    post :add_sicario, :login => 'MrMan'
    assert_response :redirect
    @bd.reload
    assert_equal 'MrMan', @bd.sicarios[0].login
  end

  test "should_del_sicario" do
    test_should_add_sicario
    assert_difference("@bd.sicarios.size", -1) do
      post :del_sicario, :user_id => Ias.MrMan.id
      @bd.reload
      @bd.sicarios.each do |sicario| puts sicario.login end
    end
  end
end
