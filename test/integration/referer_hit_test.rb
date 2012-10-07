# -*- encoding : utf-8 -*-
require 'test_helper'

class RefererHitTest < ActionController::IntegrationTest
  def setup
    host! App.domain
  end

  test "should_account_refered_hit" do
    u1 = User.find(1)
    get '/?rusid=1'
    assert_response :success, @response.body
  end
end
