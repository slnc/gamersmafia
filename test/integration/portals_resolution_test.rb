require "#{File.dirname(__FILE__)}/../test_helper"

class PortalsResolutionTest < ActionController::IntegrationTest
  
  
  test "urls of contents should be correct" do
    host! App.domain
    g = Game.new(:name => 'Diablo 3', :code => 'diablo')
    assert_count_increases(Game) do
      g.save
    end
    t = Term.single_toplevel(:slug => g.code)
    sym_login 'superadmin', 'lalala'
    assert_count_increases(News) do
      post '/noticias/create', { :news => {:title => 'footapang', :description => 'bartapang'}, :root_terms => [t.id.to_s] }
      assert_response :redirect
    end
    n = News.find(:first, :order => 'id desc')
    assert !n.is_public?
    host! App.domain
    post '/admin/contenidos/mass_moderate', { :mass_action => 'publish', :items => [n.unique_content_id.to_s] }
    assert_redirected_to '/admin/contenidos'
    n.reload
    assert n.is_public?
    assert_equal "http://#{g.code}.#{App.domain}/noticias/show/#{n.id}", n.unique_content.url
  end
  
  test "should_resolve_main" do
    host! App.domain
    get '/'
    assert @controller.portal.kind_of?(GmPortal), @response.body
    assert_response :success, @response.body
  end
  
  test "should_resolve_subdomain_as_faction_portal" do
    p = FactionsPortal.find_by_code('ut')
    host! "#{p.code}.#{App.domain}"
    get '/'
    assert_response :success, @response.body
    
    assert_equal p.code, @controller.portal_code
  end
  
  
  test "should_resolve_subdomain_as_clan_portal" do
    
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
