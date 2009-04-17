require 'test_helper'
require 'cuenta/apuestas_controller'

# Re-raise errors caught by the controller.
class Cuenta::ApuestasController; def rescue_action(e) raise e end; end

class Cuenta::ApuestasControllerTest < ActionController::TestCase
  def test_index
    sym_login 1
    get :index
    assert_response :success
  end
end
