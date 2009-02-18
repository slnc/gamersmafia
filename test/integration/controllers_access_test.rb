require "#{File.dirname(__FILE__)}/../test_helper"

class ControllersAccessTest < ActionController::IntegrationTest
  def test_should_not_allow_access_to_restricted_pages_from_clans_portal
    c = Clan.find_by_tag('mapaches')
    c.activate_website if not c.website_activated?
    ['competiciones', 'curiosidades', 'coverages', 'tutoriales', 'reviews', 'apuestas', 'clanes', 'entrevistas'].each do |url|
      host! "#{Cms::to_fqdn(c.tag)}.#{App.domain}"
      get "/#{url}"
      assert_response 404, url
      assert @response.body.match('ActiveRecord::RecordNotFound'), @response.body
      assert controller.portal.kind_of?(ClansPortal)
    end
  end
  
  def test_test_app_config
    assert_not_nil App.domain
  end
end
