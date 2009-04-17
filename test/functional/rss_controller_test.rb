require 'test_helper'
require 'feed_tools'

class RssControllerTest < ActionController::TestCase


  #assert_valid_feed [ :noticias ]

  #test "should_load_noticias" do
  #  get :noticias
  #  assert_response :success
  #  assert_template 'rss/noticias'
  #end
  #
  test "rss_noticias" do
    get :noticias
    assert_response :success
    assert_valid_feed2
  end

  test "should_not_access_moderation_queue_if_no_secret_given" do
    assert_raises(AccessDenied) do
      get :cola_moderacion
    end
  end

  test "should_access_moderation_queue_if_given_secret" do
    get :cola_moderacion, :secret => User.find(1).secret
    assert_response :success
    assert_template 'rss/cola_moderacion'
    assert_valid_feed2
  end
end
