# -*- encoding : utf-8 -*-
require 'test_helper'

class StaffPositionsControllerTest < ActionController::TestCase
  test "staff" do
    get :index
    assert_response :success
  end
end
