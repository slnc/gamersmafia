# -*- encoding : utf-8 -*-
require 'test_helper'

class RssControllerTest < ActionController::TestCase

  test "rss_noticias" do
    get :noticias
    assert_response :success
    assert_valid_feed2
  end

end
