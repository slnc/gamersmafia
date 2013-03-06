# -*- encoding : utf-8 -*-
require 'test_helper'

class Cuenta::SkinsControllerTest < ActionController::TestCase

  def setup
    if !File.exists?(Skin::FAVICONS_CSS_FILENAME)
      open(Skin::FAVICONS_CSS_FILENAME, "w").write("// dummy css for tests")
    end
  end

  test "trying to use a deleted skin should work properly" do
      test_activate_my_own_skin_should_work
      post :destroy, :id => @skin.id
      assert_response :redirect

      assert Skin.find_by_id(@skin.id).nil?

      get :index
      assert_response :success
      assert @response.body.index("skins/default/")
  end

  test "activate my own skin should work" do
      test_should_create_factions_skin_if_everything_ok
      post :activate, :skin => @skin.id
      assert_response :redirect
      get :index
      assert_response :success
      assert @response.body.index("storage/skins/#{@skin.hid}/")
  end

  test "make_public_should_make_skin_public" do
    test_should_create_factions_skin_if_everything_ok
    assert !@skin.is_public?
    post :make_public, :id => @skin.id
    assert_redirected_to "/cuenta/skins"
    @skin.reload
    assert @skin.is_public?
  end

  test "make_private_should_make_skin_private" do
    test_should_create_factions_skin_if_everything_ok
    assert @skin.update_attributes(:is_public => true)
    assert @skin.is_public?
    post :make_private, :id => @skin.id
    assert_redirected_to "/cuenta/skins"
    @skin.reload
    assert !@skin.is_public?
  end

  test "activate private skin from other shouldn't work" do
      test_should_create_factions_skin_if_everything_ok
      sym_login 2
      assert_raises(ActiveRecord::RecordNotFound) { post :activate, :skin => @skin.id }
  end

  test "activate public skin from other should work" do
      test_should_create_factions_skin_if_everything_ok
      assert @skin.update_attributes(:is_public => true)
      sym_login 2
      post :activate, :skin => @skin.id
      assert_response :redirect
      get :index
      assert_response :success
      assert @response.body.index("storage/skins/#{@skin.hid}/")
  end

  test "reset skin should work" do
      test_activate_my_own_skin_should_work
      post :activate, :skin => '-1'
      assert_response :redirect
      get :index
      assert_response :success
      assert @response.body.index("skins/default/")
  end

  test "index_should_work" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "should_create_factions_skin_if_everything_ok" do
    Skin.any_instance.stubs(:call_yuicompressor).at_least_once
    sym_login 1
    assert_count_increases(Skin) do
      post :create, {:skin => {:name => 'foooskin' }}
      assert_response :redirect
    end
    @skin = Skin.find(:first, :order => 'id DESC')
    assert_not_nil @skin.intelliskin_header
  end

  test "update_should_work" do
    test_should_create_factions_skin_if_everything_ok
    post :update, { :id => @skin.id, :skin => { :name => 'nuevo name'}}
    assert_response :redirect
    @skin.reload
    assert_equal 'nuevo name', @skin.name
  end

  test "should_create_clans_skin_if_everything_ok" do
    Skin.any_instance.stubs(:call_yuicompressor).at_least_once
    sym_login 1
    assert_count_increases(Skin) do
      post :create, {:skin => {:name => 'foooskin'}}
      assert_response :redirect
    end
  end

  test "should_edit" do
    Skin.any_instance.stubs(:call_yuicompressor).at_least_once
    Skin.find(1).send :setup_initial_zip
    sym_login 1
    get :edit, {:id => 1}
    assert_response :success
  end

  test "should_delete_clans_skin_if_everything_ok" do
    sym_login 1
    assert_count_decreases(Skin) do
      post :destroy, {:id => 1}
      assert_response :redirect
    end
  end
end
