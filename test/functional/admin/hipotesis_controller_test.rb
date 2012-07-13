require 'test_helper'

class Admin::HipotesisControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :nueva, :create, :editar, :update ]

  def setup
    sym_login 1
  end

  test "index" do
    get :index
    assert_response :success
  end

  test "nueva" do
    get :nueva
    assert_response :success
  end

  test "create" do
    assert_count_increases(AbTest) do
      self.create_abtest
    end
    assert_response :redirect
  end

  test "editar" do
    self.create_abtest
    get :editar, :id => @ab_test.id
    assert_response :success
  end

  test "update" do
    self.create_abtest
    post :update, :id => @ab_test.id, :ab_test => {:name => 'funicular'}
    assert_response :redirect
    @ab_test.reload
    assert_equal 'funicular', @ab_test.name
  end

  test "destroy" do
    self.create_abtest
    assert_count_decreases(AbTest) do
      post :destroy, :id => @ab_test.id
    end
    assert_response :redirect
  end

  def create_abtest
    post :create, :ab_test => {
      :name => 'babbab',
      :metrics => ['comments'],
      :min_difference => '0.05',
      :treatments => 3,
    }
    @ab_test = AbTest.find(:first, :order => 'id desc')
  end
end
