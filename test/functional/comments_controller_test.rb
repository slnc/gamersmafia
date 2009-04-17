require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  def setup
    @controller = CommentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end
  
  NEW_COMMENT_OPTS = { :comment => {:comment => 'foo', :content_id => Content.find(:first).id}, :add_to_tracker => '1', :redirto => '/foo' }
  
  def test_should_allow_registered_user_to_comment
    c_initial = Comment.count
    sym_login :panzer
    panzer = User.find_by_login('panzer')
    post :create, NEW_COMMENT_OPTS
    assert_redirected_to '/foo'
    assert_equal c_initial + 1, Comment.count
    @c = Comment.find(:first, :order => 'id DESC')
    assert_equal panzer.id, @c.user_id
  end
  
  def test_should_destroy
    test_should_allow_registered_user_to_comment
    sym_login 1
    post :destroy, { :id => @c.id}
    assert_response :redirect
    assert Comment.find_by_id(@c.id).deleted
  end
  
  def test_should_update
    test_should_allow_registered_user_to_comment
    orig = @c.comment
    sym_login 1
    post :update, { :id => @c.id, :comment => {:comment => 'feoooote'}}
    assert_response :redirect
    @c.reload
    assert_equal 'feoooote', @c.comment
    assert_equal orig, @c.lastowner_version
    assert_equal 1, @c.lastedited_by_user_id
  end
  
  def test_should_edit_previous_comment_if_last_comment_is_yours_and_less_than_1h
    test_should_allow_registered_user_to_comment
    prev = Comment.find(:first, :order => 'id DESC')
    
    c_initial = Comment.count
    opts = {}.merge(NEW_COMMENT_OPTS)
    opts[:comment][:comment] ='bar'
    post :create, opts
    assert_redirected_to '/foo'
    assert_equal c_initial, Comment.count
    @c = Comment.find(:first, :order => 'id DESC')
    
    assert_equal @c.id, prev.id
    assert_equal "#{prev.comment}<br /><br /><strong>Editado</strong>: bar", @c.comment
  end
  
  def test_should_add_to_tracker_if_comment_created_ok
    u = User.find_by_login(:panzer)
    u.notifications_trackerupdates = true
    u.save
    items_count = u.tracker_items.count
    test_should_allow_registered_user_to_comment
    assert_equal items_count + 1, u.tracker_items.count
  end
  
  def test_should_not_break_if_trying_to_add_to_tracker_if_comment_created_ok_twice
    u = User.find_by_login(:panzer)
    items_count = u.tracker_items.count
    test_should_add_to_tracker_if_comment_created_ok
    post :create, NEW_COMMENT_OPTS
    assert_response :redirect
    assert_equal items_count + 1, u.tracker_items.count
  end
  
  def test_rate
    test_should_allow_registered_user_to_comment
    sym_login 1
    User.db_query("UPDATE users set created_on = '2006-01-01 00:00:00' where id = 1")
    assert_count_increases(CommentsValoration) do
      post :rate, {:comment_id => @c.id, :rate_id => 1}
    end
    assert_response :success
  end
  
  def test_report
    test_should_allow_registered_user_to_comment
    sym_login 1
    assert_count_increases(SlogEntry) do
      post :report, :id => @c.id
    end
    assert_response :success
  end
  
  def test_should_not_add_to_tracker_if_comment_created_ok_but_not_selected
    u = User.find_by_login(:panzer)
    u.notifications_trackerupdates = true
    u.save
    items_count = u.tracker_items.count
    c_initial = Comment.count
    sym_login :panzer
    panzer = User.find_by_login('panzer')
    post :create, NEW_COMMENT_OPTS.merge({:add_to_tracker => '0'})
    assert_redirected_to '/foo'
    assert_equal c_initial + 1, Comment.count
    assert_equal items_count, u.tracker_items.count
  end
  
  
  def test_should_redirect_to_home_if_commenting_to_nonexistent_content
    sym_login :panzer
    assert_raises(ActiveRecord::RecordNotFound) {
      post :create, NEW_COMMENT_OPTS.merge({:comment => { :content_id => 0}})
    }
  end
  
  def test_should_edit_comment
    test_should_allow_registered_user_to_comment
    get :edit, { :id =>  @c.id }
    assert_response :success
  end
  
  def test_report_should_raise_access_denied_if_not_right_user
    test_should_allow_registered_user_to_comment
    sym_login 2
    assert_raises(AccessDenied) do
      post :report, :id => @c.id
    end
  end
end