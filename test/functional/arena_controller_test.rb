require 'test_helper'
require 'arena_controller'

# Re-raise errors caught by the controller.
class ArenaController; def rescue_action(e) raise e end; end

class ArenaControllerTest < ActionController::TestCase


  def test_truth
    assert true
  end
end
