require 'test_helper'


class SessionsActivationTest < ActionController::IntegrationTest
  def setup
    host! App.domain
  end

  def test_should_not_start_session_by_default
    get '/'
    assert_response :success
    assert_nil cookies['adn2']
    assert session.kind_of?(Hash)
  end

  def test_should_start_session_if_autologin_cookie_present
    cookies['ak'] = CGI::Cookie.new('autologin', 'foobar')    
    get '/'
    assert_response :success
    assert_not_nil cookies['adn2']
    assert !session.kind_of?(Hash)
  end

  def test_should_start_session_if_session_cookie_present
    # cookies['adn2'] = CGI::Cookie.new('adn2', 'foobar')
    sym_login 'superadmin', 'lalala'
    
    get '/'
    assert_response :success
    assert_not_nil cookies['adn2']
    assert !session.kind_of?(Hash)
  end

  def test_should_start_session_if_accessing_x
    #cookies['adn2'] = CGI::Cookie.new('adn2', 'foobar')    
    get '/site/x'
    assert_response :success
    assert_not_nil cookies['adn2']
    assert !session.kind_of?(Hash)
  end
end
