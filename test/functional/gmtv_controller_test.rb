require File.dirname(__FILE__) + '/../test_helper'
require 'gmtv_controller'

# Re-raise errors caught by the controller.
class GmtvController; def rescue_action(e) raise e end; end

class GmtvControllerTest < ActiveSupport::TestCase
  def setup
    @controller = GmtvController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  # Replace this with your real tests.
  def test_should_return_channels_if_gm
    get :channels
    assert_response :success
  end
  
  def test_should_return_channels_if_factions_portal
    @request.host = "ut.gamersmafia.com"
    test_should_return_channels_if_gm
  end
  
  def test_should_return_channels_if_platforms_portal
    @request.host = "wii.gamersmafia.com"
    test_should_return_channels_if_gm
  end
  
  def test_should_return_channels_if_clans_portal
    @request.host = "#{ClansPortal.find(:first).code}.gamersmafia.com"
    test_should_return_channels_if_gm
  end
end
