require 'test_helper'

class DistritoControllerTest < ActionController::TestCase
  test "index" do
    @request.host = "anime.#{App.domain}"
    get :index
    assert_response :success
  end
end
