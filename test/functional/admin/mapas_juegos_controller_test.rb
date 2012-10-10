# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::MapasJuegosControllerTest < ActionController::TestCase

  test "index" do
    sym_login 1
    get :index, {}
    assert_response :success
    assert_template 'index'
  end

  test "new" do
    sym_login 1
    get :new, {}

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:games_map)
  end

  test "create" do
    sym_login 1
    assert_difference("GamesMap.count") do
      post :create, {:games_map => {:game_id => 1, :name => 'foo'}}
    end

    assert_response :redirect
    assert_redirected_to :action => 'index'
  end

  test "edit" do
    sym_login 1
    get :edit, {:id => 1}

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:games_map)
    assert assigns(:games_map).valid?
  end

  test "update" do
    sym_login 1
    post :update, {:id => 1, :games_map =>  {}}
    assert_response :redirect
    assert_redirected_to :action => 'edit', :id => 1
  end

  test "destroy" do
    sym_login 1
    assert_not_nil GamesMap.find(1)

    post :destroy, {:id => 1}, {:user => 1}
    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_raise(ActiveRecord::RecordNotFound) {
      GamesMap.find(1)
    }
  end
end
