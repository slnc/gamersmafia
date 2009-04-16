require 'test_helper'
require 'comunidad_controller'

# Re-raise errors caught by the controller.
class ComunidadController; def rescue_action(e) raise e end; end

class ComunidadControllerTest < ActionController::TestCase
  def setup
    @controller = ComunidadController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
