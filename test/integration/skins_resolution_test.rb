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

  test "should_resolve_subdomain_as_faction_portal" do
    portal = FactionsPortal.find_by_code('ut')
    host! "#{portal.code}.#{App.domain}"
    get '/'
    assert_response :success, @response.body
    assert @controller.skin.hid == 'default'
    # TODO more tests here flunk('TODO')
  end
end
