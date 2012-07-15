# -*- encoding : utf-8 -*-
require 'test_helper'

class GmtvControllerTest < ActionController::TestCase


  test "should_return_channels_if_gm" do
    get :channels
    assert_response :success
  end

  test "should_return_channels_if_factions_portal" do
    @request.host = "ut.gamersmafia.com"
    test_should_return_channels_if_gm
  end

  test "should_return_channels_if_platforms_portal" do
    @request.host = "wii.gamersmafia.com"
    test_should_return_channels_if_gm
  end


end
