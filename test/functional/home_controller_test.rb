# -*- encoding : utf-8 -*-
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

  test "home" do
    get :index
    assert_response :success
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
  end

  test "should show hq menu if any relevant skill" do
    u2 = User.find(2)
    sym_login u2
    %w(Capo EditFaq).each do |skill|
      u2.users_skills.clear
      give_skill(u2, skill)
      get :index
      assert_not_nil @response.body.index("stats_hipotesis")
    end
  end

  test "should show not hq menu if no relevant skill" do
    u2 = User.find(2)
    sym_login u2
    u2.users_skills.clear
    get :index
    assert_nil @response.body.index("stats_hipotesis")
  end
end
