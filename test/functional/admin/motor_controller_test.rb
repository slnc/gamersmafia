require 'test_helper'

class Admin::MotorControllerTest < ActionController::TestCase
  test "should_show_index" do
    sym_login 1
    get :index
    assert_response :success
  end
end
