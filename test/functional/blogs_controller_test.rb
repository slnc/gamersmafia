require 'test_helper'

class BlogsControllerTest < ActionController::TestCase


  # Replace this with your real tests.
  test "index_should_work" do
    get :index
    assert_response :success
    assert_template 'index'
  end

  test "blog_should_work_if_user_has_blogentries" do
    get :blog, {:login => User.find(1).login }
    assert_response :success
    assert_template 'blog'
  end

  test "blog_shouldnt_work_if_user_has_noblogentries" do
    assert_raises(ActiveRecord::RecordNotFound) { get :blog, {:login => User.find(:first, :conditions => ["id NOT IN (SELECT distinct(user_id) from blogentries)"]).login } }
  end

  test "blog_shouldnt_work_if_user_doesnt_exists" do
    assert_raises(ActiveRecord::RecordNotFound) { get :blog, {:login => 'A?DSAD???_' } }
  end

  test "blogentry_should_work_if_blogentry_exists" do
    get :blogentry, {:login => User.find(1).login, :id => Blogentry.find(:published, :order => 'id', :limit => 1)[0].id }
    assert_response :success
    assert_template 'blogentry'
  end

  test "should_notshow_users_blogentry_if_existing_but_unpublished" do
    be = Blogentry.find(1)
    assert be.update_attributes({:state => Cms::DELETED})
    assert_equal Cms::DELETED, be.state
    assert_raises(ActiveRecord::RecordNotFound) { get :blogentry, { :login => 'superadmin', :id => 1 } }
  end

  test "ranking_should_work" do
    get :ranking
    assert_response :success
    assert_template 'ranking'
  end

  test "close_blogentry" do
    be = Blogentry.find(1)
    sym_login be.user_id
    post :close, :id => be.id
    assert_response :redirect
    be.reload
    assert be.closed?
  end
end
