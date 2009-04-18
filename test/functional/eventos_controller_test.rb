require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'

class EventosControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Event', :form_vars => {:title => 'footapang', :starts_on => Time.now, :ends_on => 7.days.since}, :root_terms => 1 
  test_min_acl_level :user, [ :member_join, :member_leave ], :post



  test "join" do
    e = Event.find(:first, :order => 'id DESC')
    assert_nil e.users.find_by_id(1)
    sym_login 1
    post :member_join, { :id => e.id }
    assert_not_nil e.users.find_by_id(1)
  end

  test "leave" do
    test_join
    e = Event.find(:first, :order => 'id DESC')
    post :member_leave, { :id => e.id }
    assert_nil e.users.find_by_id(1)
  end

  test "dia" do
    get :dia, { :id => '20060101' }
    assert_response :success
    assert_template 'dia'
  end
  
  test "dia_null" do
    assert_raises(ActiveRecord::RecordNotFound) { get :dia }
  end
end
