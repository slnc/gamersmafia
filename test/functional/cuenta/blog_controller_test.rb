require 'test_helper'

class Cuenta::BlogControllerTest < ActionController::TestCase

  
  def test_index_should_work
    sym_login 1
    get :index
    assert_response :success
  end
  
  def test_new_should_work
    sym_login 1
    get :new
    assert_response :success
  end
  
  def test_edit_should_work
    sym_login 1
    get :edit, { :id => 1}
    assert_response :success
  end
  
  def test_should_create_blogentry
    sym_login 2
    @u2 = User.find(2)
    be_count = @u2.blogentries.count
    post :create, { :blogentry => { :title => 'soy minerooo', :main => 'y en mi casa no lo sabennnn' } }
    assert_response :redirect
    assert_equal be_count + 1, @u2.blogentries.count
    @last = @u2.blogentries.find(:first, :order => 'id DESC')
    assert_equal Cms::PUBLISHED, @last.state
  end
  
  def test_should_add_blogentry_to_tracker
    test_should_create_blogentry
    assert @u2.tracker_has?(@last.unique_content.id)
  end
  
  def test_should_update_blogentry_if_owner
    test_should_create_blogentry
    post :update, { :id => @last.id, :blogentry => { :title => 'new title', :main => 'new content'}}
    assert_response :redirect
    @last.reload
    assert_equal 'new title', @last.title
    assert_equal 'new content', @last.main
  end
  
  
  def test_should_update_blogentry_if_superadmin
    test_should_create_blogentry
    sym_login 1
    post :update, { :id => @last.id, :blogentry => { :title => 'new title', :main => 'new content'}}
    assert_response :redirect
    @last.reload
    assert_equal 'new title', @last.title
    assert_equal 'new content', @last.main
  end
  
  def test_should_not_update_blogentry_if_not_owner
    test_should_create_blogentry
    sym_login 3
    assert_raises(ActiveRecord::RecordNotFound) { post :update, { :id => @last.id, :blogentry => { :title => 'new title', :content => 'new content'}} }
  end
  
  def test_should_delete_blogentry_if_owner
    test_should_create_blogentry
    post :destroy, { :id => @last.id }
    assert_response :redirect
    @last.reload
    assert_equal Cms::DELETED, @last.state
  end
  
  def test_should_delete_blogentry_if_superadmin
    test_should_create_blogentry
    sym_login 1
    post :destroy, { :id => @last.id }
    assert_response :redirect
    @last.reload
    assert_equal Cms::DELETED, @last.state
  end
  
  def test_should_not_delete_blogentry_no_rights
    test_should_create_blogentry
    sym_login 3
    assert_raises(ActiveRecord::RecordNotFound) { post :destroy, { :id => @last.id } }
  end
end
