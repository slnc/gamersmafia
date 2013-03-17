require 'test_helper'

class GamingPlatformsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get platform" do
    get :gaming_platform
    assert_response :success
  end

end
