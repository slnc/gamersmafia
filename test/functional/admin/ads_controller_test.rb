# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::AdsControllerTest < ActionController::TestCase

  test "index no skill" do
    sym_login 2
    assert_raises(AccessDenied) do
      get :index
    end
    assert_response :success
  end

  test "index" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "new" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "create" do
    sym_login 1
    assert_count_increases(Ad) do
      post :create, { :ad => { :name => 'fourling', :html => 'bbbb'}}
    end
    assert_response :redirect
  end

  test "edit" do
    test_create
    get :edit, :id => Ad.find(:first).id
    assert_response :success
  end

  test "update" do
    test_create

    post :update, {
        :id => Ad.find(:first).id,
        :ad => {
            :name => 'fourling2',
            :html => 'bbbb',
        },
    }

    assert_response :redirect
    assert_equal 'fourling2', Ad.find(:first, :order => 'id desc').name
  end
end
