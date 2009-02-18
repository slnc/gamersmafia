require File.dirname(__FILE__) + '/../../test_helper'

class Admin::MotorControllerTest < ActionController::TestCase
  def test_should_show_index
    sym_login 1
    get :index
    assert_response :success
  end
end
