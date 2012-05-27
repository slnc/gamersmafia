require 'test_helper'

class Admin::HipotesisControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :nueva, :create, :editar, :update ]

  test "index" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "nueva" do
    sym_login 1
    get :nueva
    assert_response :success
  end

  test "create" do
    sym_login 1
    assert_count_increases(AbTest) do
      post :create, :ab_test => {
        :name => 'babbab',
        :metrics => ['comments'],
        :min_difference => '0.05',
        :treatments => 3,
      }
    end
    assert_response :redirect
    @ab_test = AbTest.find(:first, :order => 'id desc')
  end

  test "editar" do
    test_create
    get :editar, :id => @ab_test.id
    assert_response :success
  end

  test "update" do
    test_create
    post :update, :id => @ab_test.id, :ab_test => {:name => 'funicular'}
    assert_response :redirect
    @ab_test.reload
    assert_equal 'funicular', @ab_test.name
  end

  test "destroy" do
    test_create
    assert_count_decreases(AbTest) do
      post :destroy, :id => @ab_test.id
    end
    assert_response :redirect
  end
end
