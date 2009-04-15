require File.dirname(__FILE__) + '/../test_helper'
require 'blogs_controller'

# Re-raise errors caught by the controller.
class BlogsController; def rescue_action(e) raise e end; end

class BlogsControllerTest < ActiveSupport::TestCase
  def setup
    @controller = BlogsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  # Replace this with your real tests.
  def test_index_should_work
    get :index
    assert_response :success
    assert_template 'index'
  end
  
  def test_blog_should_work_if_user_has_blogentries
    get :blog, {:login => User.find(1).login }
    assert_response :success
    assert_template 'blog'
  end
  
  def test_blog_shouldnt_work_if_user_has_noblogentries
    assert_raises(ActiveRecord::RecordNotFound) { get :blog, {:login => User.find(:first, :conditions => ["id NOT IN (SELECT distinct(user_id) from blogentries)"]).login } }
  end
  
  def test_blog_shouldnt_work_if_user_doesnt_exists
    assert_raises(ActiveRecord::RecordNotFound) { get :blog, {:login => 'A?DSAD???_' } }
  end
  
  def test_blogentry_should_work_if_blogentry_exists
    get :blogentry, {:login => User.find(1).login, :id => Blogentry.find(:published, :order => 'id', :limit => 1)[0].id }
    assert_response :success
    assert_template 'blogentry'
  end
  
  def test_should_notshow_users_blogentry_if_existing_but_unpublished
    be = Blogentry.find(1)
    assert be.update_attributes({:state => Cms::DELETED})
    assert_equal Cms::DELETED, be.state
    assert_raises(ActiveRecord::RecordNotFound) { get :blogentry, { :login => 'superadmin', :id => 1 } }
  end
  
  def test_ranking_should_work
    get :ranking
    assert_response :success
    assert_template 'ranking'
  end
  
  def test_close_blogentry
    be = Blogentry.find(1)
    sym_login be.user_id
    post :close, :id => be.id
    assert_response :redirect
    be.reload
    assert be.closed?
  end
end
