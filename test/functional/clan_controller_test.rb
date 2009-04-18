require 'test_helper'

class ClanControllerTest < ActionController::TestCase


  test "miembros_should_work" do
    @request.host = "#{ClansPortal.find(:first).code}.#{App.domain}"
    setup_clan_skin
    get :miembros
    assert_response :success
  end
end
