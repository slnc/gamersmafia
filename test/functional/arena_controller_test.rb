require File.dirname(__FILE__) + '/../test_helper'
require 'arena_controller'

# Re-raise errors caught by the controller.
class ArenaController; def rescue_action(e) raise e end; end

class ArenaControllerTest < Test::Unit::TestCase
  def setup
    @controller = ArenaController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_truth
    assert true
  end
end
