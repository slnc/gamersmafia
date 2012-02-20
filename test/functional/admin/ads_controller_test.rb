require 'test_helper'

class Admin::AdsControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :new, :edit, :update, :destroy ]

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

    post :update, { :id => Ad.find(:first).id, :ad => { :name => 'fourling2', :html => 'bbbb'}}

    assert_response :redirect
    assert_equal 'fourling2', Ad.find(:first, :order => 'id desc').name
  end
end
