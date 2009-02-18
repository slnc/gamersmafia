require File.dirname(__FILE__) + '/../test_helper'

class SkinsResolutionTest < ActionController::IntegrationTest
  def setup
    host! App.domain
  end

  def test_should_resolve_main
    host! App.domain
    get '/'
    assert_response :success, @response.body
    assert @controller.skin.hid == 'default'
  end

  def test_should_resolve_subdomain_as_faction_portal
    p = FactionsPortal.find_by_code('ut')
    host! "#{p.code}.#{App.domain}"
    get '/'
    assert_response :success, @response.body
    assert @controller.skin.hid == 'default'
    # TODO more tests here flunk('TODO')
  end


  def test_should_resolve_subdomain_as_clan_portal
    c = Clan.find_by_tag('mapaches')
    c.activate_website if not c.website_activated?
    setup_clan_skin
    host! "#{Cms::to_fqdn(c.tag)}.#{App.domain}"
    get '/'
    assert_response :success, @response.body
    assert_not_equal 'default', @controller.skin.hid 
    # TODO more tests here flunk('TODO')
  end
end
