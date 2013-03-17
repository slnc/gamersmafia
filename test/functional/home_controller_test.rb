# -*- encoding : utf-8 -*-
require 'test_helper'

class HomeControllerTest < ActionController::TestCase
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
