require File.dirname(__FILE__) + '/../test_helper'
require 'rss_controller'
require 'feed_tools'

# Re-raise errors caught by the controller.
class RssController; def rescue_action(e) raise e end; end

class RssControllerTest < Test::Unit::TestCase
  def setup
    @controller = RssController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_rss_noticias
    get :noticias
    assert_response :success
    assert_valid_feed2
  end
end
