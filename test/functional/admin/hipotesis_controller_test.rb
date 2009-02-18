require File.dirname(__FILE__) + '/../../test_helper'

class Admin::HipotesisControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :new, :create, :edit, :update ]
  
  def test_index
    sym_login 1
    get :index
    assert_response :success
  end
  
  def test_nueva
    sym_login 1
    get :nueva
    assert_response :success
  end
  
  def test_create
    sym_login 1
    assert_count_increases(AbTest) do
      post :create, :ab_test => {:name => 'babbab', :metrics => ['comments'], :min_difference => '0.05', :treatments => 3 }
    end
    assert_response :redirect
    @ab_test = AbTest.find(:first, :order => 'id desc')
  end
  
  def test_editar
    test_create
    get :editar, :id => @ab_test.id
    assert_response :success
  end
  
  def test_update
    test_create
    post :update, :id => @ab_test.id, :ab_test => {:name => 'funicular'}
    assert_response :redirect
    @ab_test.reload
    assert_equal 'funicular', @ab_test.name
  end
  
  def test_destroy
    test_create
    assert_count_decreases(AbTest) do
      post :destroy, :id => @ab_test.id
    end
    assert_response :redirect
  end
end
