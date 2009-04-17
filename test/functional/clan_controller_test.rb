require 'test_helper'
require 'clan_controller'

# Re-raise errors caught by the controller.
class ClanController; def rescue_action(e) raise e end; end

class ClanControllerTest < ActionController::TestCase


  def test_miembros_should_work
    @request.host = "#{ClansPortal.find(:first).code}.#{App.domain}"
    setup_clan_skin
    get :miembros
    assert_response :success
  end
end
