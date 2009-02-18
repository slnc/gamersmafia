require "#{File.dirname(__FILE__)}/../test_helper"

class PortalsResolutionTest < ActionController::IntegrationTest  
  def test_should_resolve_main
    host! App.domain
    get '/'
    assert @controller.portal.kind_of?(GmPortal), @response.body
    assert_response :success, @response.body
  end

  def test_should_resolve_subdomain_as_faction_portal
    p = FactionsPortal.find_by_code('ut')
    host! "#{p.code}.#{App.domain}"
    get '/'
    assert_response :success, @response.body

    assert_equal p.code, @controller.portal_code
  end


  def test_should_resolve_subdomain_as_clan_portal
    
    c = Clan.find_by_tag('mapaches')
    c.activate_website if not c.website_activated?
    setup_clan_skin
    host! "#{Cms::to_fqdn(c.tag)}.#{App.domain}"
    get '/'
    assert_response :success, @response.body

    assert @controller.portal.kind_of?(ClansPortal)
    assert_equal Cms::to_fqdn(c.tag), @controller.portal_code
  end
end
