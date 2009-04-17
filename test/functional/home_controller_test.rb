require 'test_helper'
require 'home_controller'

# Re-raise errors caught by the controller.
class HomeController; def rescue_action(e) raise e end; end

class HomeControllerTest < ActionController::TestCase

  
  def test_comunidad
    get :comunidad
    assert_response :success
    
    sym_login 1
    get :comunidad
    assert_response :success
  end
  
  def test_facciones_should_render_index_if_no_faction_for_user
    get :facciones
    assert_response :success
  end
  
  def test_facciones_should_render_faction_home_if_faction_for_user
    u1 = User.find(1)
    Factions.user_joins_faction(u1, 1)
    assert Factions.default_faction_for_user(u1)
    sym_login u1.id
    get :facciones
    assert_response :success
  end
  
  def test_foros
    get :foros
    assert_response :success
    
    sym_login 1
    get :foros
    assert_response :success
  end
  
  def test_anunciante
    assert_raises(AccessDenied) { get :anunciante }
    
    sym_login 10
    assert_raises(AccessDenied) { get :anunciante }
    
    sym_login 1 # superadmin with no advertiser_ids
    get :anunciante
    assert_response :success
    
    sym_login 59 # advertiser
    get :anunciante
    assert_response :success
  end
  
  def test_hq    
    assert_raises(AccessDenied) { get :hq }
    
    sym_login 5
    assert_raises(AccessDenied) { get :hq }
    
    sym_login 1
    get :hq
    assert_response :success
  end
  
  # Replace this with your real tests.
  def test_home
    get :index
    assert_response :success
  end
  
  
  def test_should_show_district_portal
    @request.host = 'anime.gamersmafia.dev'
    get :index
    assert_response :success
    # assert @controller.portal.nil?
  end
  
  # testeamos aquí que el enrutado por dominios sea correcto
  def test_should_show_unknown_domain_if_unrecognized_host
    assert_raises(DomainNotFound) do
      @request.host = 'noexisto.gamersmafia.com'
      get :index
    end
    # assert_response :missing
    # assert @controller.portal.nil?
  end
  
  def test_should_show_normal_page_if_main_site
    @request.host = App.domain
    get :index
    assert_response :success
    assert_template 'gm'
    assert @controller.portal.kind_of?(GmPortal)
  end
  
  
  def test_should_show_normal_page_if_bazar_site
    @request.host = "bazar.#{App.domain}"
    get :index
    assert_response :success
    assert_template 'bazar'
    assert @controller.portal.kind_of?(BazarPortal)
  end
  
  def test_should_show_normal_page_if_arena_site
    @request.host = "arena.#{App.domain}"
    get :index
    assert_response :success
    assert_template 'arena'
    assert @controller.portal.kind_of?(ArenaPortal)
  end
  
  def test_should_show_clans_page_if_clans_portal
    @request.host = "#{ClansPortal.find(:first).code}.#{App.domain}"
    setup_clan_skin
    get :index
    assert_response :success
    assert_template 'clan'
    assert @controller.portal.kind_of?(ClansPortal)
  end
  
  def test_should_show_normal_page_if_faction_portal
    @request.host = "#{FactionsPortal.find_by_code('ut').code}.#{App.domain}"
    get :index
    assert_response :success
    assert_template 'facciones_fps'
    assert @controller.portal.kind_of?(FactionsPortal)
  end
  
  def test_should_redir_to_proper_home_if_defset_and_anonymous
    @request.cookies['defportalpref'] = CGI::Cookie.new('defportalpref', 'facciones')
    get :index
    assert_response :success
    assert_template 'facciones_unknown'
  end

  def test_home_bazar_district_shouldnt_show_bets_from_other_places
    b1 = Bet.find(1)
    assert b1.update_attributes(:closes_on => 1.day.since)
    @request.host = 'anime.gamersmafia.dev'
    get :index
    assert @response.body.index(b1.title).nil?
  end

  def test_home_bazar_district_shouldnt_show_closed_bets_from_self
    b1 = Bet.find(1)
    assert b1.update_attributes(:closes_on => 1.day.ago)
    @request.host = 'anime.gamersmafia.dev'
    get :index
    assert @response.body.index(b1.title).nil?
  end

  def test_home_bazar_district_should_show_closed_bets_from_self
    b1 = Bet.find(1)
    assert b1.update_attributes(:closes_on => 1.day.since)
    Term.single_toplevel(:slug => 'anime').link(b1.unique_content)
    @request.host = 'anime.gamersmafia.dev'
    get :index
    assert_not_nil @response.body.index(b1.title)
  end
end
