require File.dirname(__FILE__) + '/../../test_helper'
require 'cuenta/banco_controller'

# Re-raise errors caught by the controller.
class Cuenta::BancoController; def rescue_action(e) raise e end; end

class Cuenta::BancoControllerTest < Test::Unit::TestCase
  def setup
    @controller = Cuenta::BancoController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    sym_login 1
    get :index
    assert_response :success
  end
end
