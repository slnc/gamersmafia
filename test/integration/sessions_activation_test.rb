require 'test_helper'


class SessionsActivationTest < ActionController::IntegrationTest
  def setup
    host! App.domain
  end

  test "should_start_session_if_autologin_cookie_present" do
    cookies['ak'] = 'foobar'    
    get '/'
    assert_response :success
    assert_not_nil cookies['adn2']
  end

  test "should_start_session_if_session_cookie_present" do
    sym_login 'superadmin', 'lalala'
    
    get '/'
    assert_response :success
    assert_not_nil cookies['adn2']
  end

  test "should_start_session_if_accessing_x" do    
    get '/site/x'
    assert_response :success
    assert_not_nil cookies['adn2']
  end
end
