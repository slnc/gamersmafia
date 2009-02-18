require File.dirname(__FILE__) + '/../test_helper'

class DistritoControllerTest < ActionController::TestCase
  def test_index
    @request.host = "anime.#{App.domain}"
    get :index
    assert_response :success
  end
end
