require File.dirname(__FILE__) + '/../../test_helper'
require 'cuenta/guids_controller'

# Re-raise errors caught by the controller.
class Cuenta::GuidsController; def rescue_action(e) raise e end; end

class Cuenta::GuidsControllerTest < ActiveSupport::TestCase
  test_min_acl_level :user, [ :index, :guardar ]

  def setup
    @controller = Cuenta::GuidsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_index_should_work
    sym_login 1
    get :index
    assert_response :success
  end
  
  def test_guardar_should_work_if_giving_reason
    sym_login 1
    @u1 = User.find(1)
    @g1 = Game.find(1)
    post :guardar, { "guid#{@g1.id}" => {:guid => '0123456789', :reason => 'soy feo'}}
    assert_response :redirect
    assert_equal '0123456789', @u1.users_guids.find_last(@u1, @g1).guid 
  end
  
  def test_guardar_shouldnt_throw_500_if_duped
    test_guardar_should_work_if_giving_reason
    sym_login 2
    @u2 = User.find(2)
    @g1 = Game.find(1)
    post :guardar, { "guid#{@g1.id}" => {:guid => '0123456789', :reason => 'soy feo'}}
    assert_response :redirect
    assert_not_nil flash[:error]
    assert_nil @u2.users_guids.find_last(@u2, @g1) 
  end
  
  def test_guardar_should_work_if_doing_nothing
    test_guardar_should_work_if_giving_reason
    post :guardar, { "guid#{@g1.id}" => {:guid => '0123456789', :reason => ''}}
    assert_response :redirect
    assert_nil flash[:error]
  end
  
  def test_guardar_shouldnt_work_if_changing_without_giving_reason
    test_guardar_should_work_if_giving_reason
    post :guardar, { "guid#{@g1.id}" => {:guid => '0123456788', :reason => ''}}
    assert_response :redirect
    assert_not_nil flash[:error]
    assert_equal '0123456789', @u1.users_guids.find_last(@u1, @g1).guid
  end
end
