# -*- encoding : utf-8 -*-
require 'test_helper'

class ErrorHandlingTest < ActionController::IntegrationTest
  def setup
    host! App.domain
  end

  test "should update stats on internal 404" do
    Keystore.expects(:incr)
    get '/nonexisting', {}, { 'HTTP_REFERER' => "http://gamersmafia.com/" }
    assert_response :missing
  end

  test "should update stats on external 404 with referer" do
    Keystore.expects(:incr)
    get '/nonexisting', {}, { 'HTTP_REFERER' => "http://google.com/" }
    assert_response :missing
  end

  test "should update stats on external 404 without referer" do
    Keystore.expects(:incr)
    get '/nonexisting', {}
    assert_response :missing
  end
end
