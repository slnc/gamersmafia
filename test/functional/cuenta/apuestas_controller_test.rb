require File.dirname(__FILE__) + '/../../test_helper'
require 'cuenta/apuestas_controller'

# Re-raise errors caught by the controller.
class Cuenta::ApuestasController; def rescue_action(e) raise e end; end

class Cuenta::ApuestasControllerTest < Test::Unit::TestCase
  def setup
    @controller = Cuenta::ApuestasController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    sym_login 1
    get :index
    assert_response :success
  end
end
