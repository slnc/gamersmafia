require "#{File.dirname(__FILE__)}/../test_helper"

class UserLoginTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  test "should_login_if_valid_data" do
    post '/cuenta/do_login', { :login => :superadmin, :password => :lalala }
    assert_response :redirect
    assert_not_nil request.session[:user]
  end

  test "should_logout" do
    test_should_login_if_valid_data
    post '/cuenta/logout'
    assert_response :redirect
    assert_nil request.session[:user]
  end

  
end
