# -*- encoding : utf-8 -*-
require 'test_helper'


class ClanWebsitesIntegrationTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  # COMMON
  test "clan_website_should_work_right_after_buying_the_product" do

  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
