# -*- encoding : utf-8 -*-
require 'test_helper'

class SkinsResolutionTest < ActionController::IntegrationTest
  def setup
    host! App.domain
  end

  test "should_resolve_main" do
    host! App.domain
    get '/'
    assert_response :success, @response.body
    assert @controller.skin.hid == 'default'
  end
end
