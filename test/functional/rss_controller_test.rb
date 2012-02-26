require 'test_helper'
require 'feed_tools'

class RssControllerTest < ActionController::TestCase

  test "rss_noticias" do
    get :noticias
    assert_response :success
    assert_valid_feed2
  end

end
