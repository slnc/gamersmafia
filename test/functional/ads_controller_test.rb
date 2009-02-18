require File.dirname(__FILE__) + '/../test_helper'

class AdsControllerTest < ActionController::TestCase
  
  def test_works_with_advertiser
    sym_login 59
    get :slot, :id => 1
    assert_response :success
  end
end
