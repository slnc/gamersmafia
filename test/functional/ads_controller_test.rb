# -*- encoding : utf-8 -*-
require 'test_helper'

class AdsControllerTest < ActionController::TestCase
  test "works_with_advertiser" do
    sym_login 59
    get :slot, :id => 1
    assert_response :success
  end
end
