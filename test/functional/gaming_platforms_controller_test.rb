require 'test_helper'

class GamingPlatformsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get platform" do
    get :platform
    assert_response :success
  end

end
