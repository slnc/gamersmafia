require 'test_helper'

class Cuenta::ApuestasControllerTest < ActionController::TestCase
  def test_index
    sym_login 1
    get :index
    assert_response :success
  end
end
