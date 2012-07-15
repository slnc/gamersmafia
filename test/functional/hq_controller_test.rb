# -*- encoding : utf-8 -*-
require 'test_helper'

class HqControllerTest < ActionController::TestCase

  test "bans_requests" do
    assert_raises(AccessDenied) { get :bans_requests }
    sym_login 1
    get :bans_requests
    assert_response :success
  end

    test "antifloods" do
    assert_raises(AccessDenied) { get :antifloods }
    sym_login 1
    get :antifloods
    assert_response :success
  end

    test "slog_archive" do
    assert_raises(AccessDenied) { get :slog_archive }
    sym_login 1
    get :slog_archive
    assert_response :success
  end
end
