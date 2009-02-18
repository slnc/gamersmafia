require File.dirname(__FILE__) + '/../test_helper'

class HqControllerTest < ActionController::TestCase

  def test_bans_requests
    assert_raises(AccessDenied) { get :bans_requests }
    sym_login 1
    get :bans_requests
    assert_response :success
  end
  
    def test_antifloods
    assert_raises(AccessDenied) { get :antifloods }
    sym_login 1
    get :antifloods
    assert_response :success
  end
  
    def test_slog_archive
    assert_raises(AccessDenied) { get :slog_archive }
    sym_login 1
    get :slog_archive
    assert_response :success
  end
end
