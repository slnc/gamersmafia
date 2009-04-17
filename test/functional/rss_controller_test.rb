require 'test_helper'
require 'rss_controller'
require 'feed_tools'

# Re-raise errors caught by the controller.
class RssController; def rescue_action(e) raise e end; end

class RssControllerTest < ActionController::TestCase


  #assert_valid_feed [ :noticias ]

  #def test_should_load_noticias
  #  get :noticias
  #  assert_response :success
  #  assert_template 'rss/noticias'
  #end
  #
  def test_rss_noticias
    get :noticias
    assert_response :success
    assert_valid_feed2
  end

  def test_should_not_access_moderation_queue_if_no_secret_given
    assert_raises(AccessDenied) do
      get :cola_moderacion
    end
  end

  def test_should_access_moderation_queue_if_given_secret
    get :cola_moderacion, :secret => User.find(1).secret
    assert_response :success
    assert_template 'rss/cola_moderacion'
    assert_valid_feed2
  end
end
