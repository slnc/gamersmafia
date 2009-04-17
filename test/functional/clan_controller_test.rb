require 'test_helper'

class ClanControllerTest < ActionController::TestCase


  def test_miembros_should_work
    @request.host = "#{ClansPortal.find(:first).code}.#{App.domain}"
    setup_clan_skin
    get :miembros
    assert_response :success
  end
end
