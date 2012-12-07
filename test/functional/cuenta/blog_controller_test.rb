# -*- encoding : utf-8 -*-
require 'test_helper'

class Cuenta::BlogControllerTest < ActionController::TestCase


  test "index_should_work" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "new_should_work" do
    sym_login 1
    get :new
    assert_response :success
  end

  test "edit_should_work" do
    sym_login 1
    get :edit, { :id => 1}
    assert_response :success
  end

  test "should_create_blogentry" do
    sym_login 2
    @u2 = User.find(2)
    be_count = @u2.blogentries.count
    post :create, { :blogentry => { :title => 'soy minerooo', :main => 'y en mi casa no lo sabennnn' } }
    assert_response :redirect
    assert_equal be_count + 1, @u2.blogentries.count
    @last = @u2.blogentries.find(:first, :order => 'id DESC')
    assert_equal Cms::PUBLISHED, @last.state
  end

  test "should_add_blogentry_to_tracker" do
    test_should_create_blogentry
    assert @u2.tracker_has?(@last.id)
  end

  test "should_update_blogentry_if_owner" do
    test_should_create_blogentry
    post :update, { :id => @last.id, :blogentry => { :title => 'new title', :main => 'new content'}}
    assert_response :redirect
    @last.reload
    assert_equal 'new title', @last.title
    assert_equal 'new content', @last.main
  end


  test "should_update_blogentry_if_superadmin" do
    test_should_create_blogentry
    sym_login 1
    post :update, { :id => @last.id, :blogentry => { :title => 'new title', :main => 'new content'}}
    assert_response :redirect
    @last.reload
    assert_equal 'new title', @last.title
    assert_equal 'new content', @last.main
  end

  test "should_not_update_blogentry_if_not_owner" do
    test_should_create_blogentry
    sym_login 3
    assert_raises(ActiveRecord::RecordNotFound) { post :update, { :id => @last.id, :blogentry => { :title => 'new title', :content => 'new content'}} }
  end

  test "should_delete_blogentry_if_owner" do
    test_should_create_blogentry
    post :destroy, { :id => @last.id }
    assert_response :redirect
    @last.reload
    assert_equal Cms::DELETED, @last.state
  end

  test "should_delete_blogentry_if_superadmin" do
    test_should_create_blogentry
    sym_login 1
    post :destroy, { :id => @last.id }
    assert_response :redirect
    @last.reload
    assert_equal Cms::DELETED, @last.state
  end

  test "should_not_delete_blogentry_no_rights" do
    test_should_create_blogentry
    sym_login 3
    assert_raises(ActiveRecord::RecordNotFound) { post :destroy, { :id => @last.id } }
  end
end
