# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::IpBansControllerTest < ActionController::TestCase

  test "index no skill" do
    sym_login 2
    assert_raises(AccessDenied) do
      get :index
    end
  end

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
      assert_response :success
    end
  end
end
