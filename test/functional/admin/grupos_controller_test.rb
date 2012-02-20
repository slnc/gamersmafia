require 'test_helper'

class Admin::GruposControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index ]

  test "index" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "edit" do
    sym_login 1
    get :edit, :id => 1
    assert_response :success
  end

  test "create" do
    sym_login 1
    assert_count_increases(Group) do
      post :create, :group => { :name => 'mechanikos', :owner_user_id => 1, :description => "foliiini" }
      assert_response :redirect
    end
  end

  test "update" do
    sym_login 1
    post :update, :id => 1, :group => { :name => 'mechanikos', :owner_user_id => 2 }
    assert_response :redirect
    g = Group.find(1)
    assert_equal 'mechanikos', g.name
    assert_equal 2, g.owner_user_id
  end

  test "add_user_to_group" do
    sym_login 1
    assert_count_increases(UsersRole) do
      post :add_user_to_group, :id => 1, :login => 'panzer'
      assert_response :success
    end
  end

  test "remove_user_from_group" do
    test_add_user_to_group
    assert_count_decreases(UsersRole) do
      post :remove_user_from_group, :id => 1, :user_id => 2
      assert_response :success
    end
  end
end
