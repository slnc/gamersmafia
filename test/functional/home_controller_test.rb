require 'test_helper'

class HomeControllerTest < ActionController::TestCase

  
  test "comunidad" do
    get :comunidad
    assert_response :success
    
    sym_login 1
    get :comunidad
    assert_response :success
  end
  
  test "facciones_should_render_index_if_no_faction_for_user" do
    get :facciones
    assert_response :success
  end
  
  test "facciones_should_render_faction_home_if_faction_for_user" do
    u1 = User.find(1)
    Factions.user_joins_faction(u1, 1)
    assert Factions.default_faction_for_user(u1)
    sym_login u1.id
    get :facciones
    assert_response :success
  end
  
  test "foros" do
    get :foros
    assert_response :success
    
    sym_login 1
    get :foros
    assert_response :success
  end
  
  test "anunciante" do
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
  
  test "hq" do    
    assert_raises(AccessDenied) { get :hq }
    
    sym_login 5
    assert_raises(AccessDenied) { get :hq }
    
    sym_login 1
    get :hq
    assert_response :success
  end
  
  # Replace this with your real tests.
  test "home" do
    get :index
    assert_response :success
  end
  
  
  test "should_show_district_portal" do
    @request.host = "anime.#{App.domain}"
    get :index
    assert_response :success
    # assert @controller.portal.nil?
  end
  
  # testeamos aquí que el enrutado por dominios sea correcto
  test "should_show_unknown_domain_if_unrecognized_host" do
    assert_raises(DomainNotFound) do
      @request.host = 'noexisto.gamersmafia.com'
      get :index
    end
    # assert_response :missing
    # assert @controller.portal.nil?
  end
  
  test "should_show_normal_page_if_main_site" do
    @request.host = App.domain
    get :index
    assert_response :success
    assert_template 'gm'
    assert @controller.portal.kind_of?(GmPortal)
  end
  
  
  test "should_show_normal_page_if_bazar_site" do
    @request.host = "bazar.#{App.domain}"
    get :index
    assert_response :success
    assert_template 'bazar'
    assert @controller.portal.kind_of?(BazarPortal)
  end
  
  test "should_show_normal_page_if_arena_site" do
    @request.host = "arena.#{App.domain}"
    get :index
    assert_response :success
    assert_template 'arena'
    assert @controller.portal.kind_of?(ArenaPortal)
  end
  
  test "should_show_clans_page_if_clans_portal" do
    @request.host = "#{ClansPortal.find(:first).code}.#{App.domain}"
    setup_clan_skin
    get :index
    assert_response :success
    assert_template 'clan'
    assert @controller.portal.kind_of?(ClansPortal)
  end
  
  test "should_show_normal_page_if_faction_portal" do
    @request.host = "#{FactionsPortal.find_by_code('ut').code}.#{App.domain}"
    get :index
    assert_response :success
    assert_template 'facciones_fps'
    assert @controller.portal.kind_of?(FactionsPortal)
  end
  
  test "should_redir_to_proper_home_if_defset_and_anonymous" do
    @request.cookies['defportalpref'] = 'facciones'
    get :index
    assert_response :success
    assert_template 'facciones_unknown'
  end

  test "home_bazar_district_shouldnt_show_bets_from_other_places" do
    b1 = Bet.find(1)
    assert b1.update_attributes(:closes_on => 1.day.since)
    @request.host = "anime.#{App.domain}"
    get :index
    assert @response.body.index(b1.title).nil?
  end

  test "home_bazar_district_shouldnt_show_closed_bets_from_self" do
    b1 = Bet.find(1)
    assert b1.update_attributes(:closes_on => 1.day.ago)
    @request.host = "anime.#{App.domain}"
    get :index
    assert @response.body.index(b1.title).nil?
  end

  test "home_bazar_district_should_show_closed_bets_from_self" do
    b1 = Bet.find(1)
    assert b1.update_attributes(:closes_on => 1.day.since)
    Term.single_toplevel(:slug => 'anime').link(b1.unique_content)
    @request.host = "anime.#{App.domain}"
    get :index
    assert_not_nil @response.body.index(b1.title)
  end
end
