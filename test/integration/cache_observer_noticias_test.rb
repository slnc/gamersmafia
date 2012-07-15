# -*- encoding : utf-8 -*-
require 'test_helper'

class CacheObserverNoticiasTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! "ut.#{App.domain}"
    faction_host Portal.find_by_code('ut')
  end

  # COMMON
  test "should_clear_cache_latest_by_cat_after_publishing_news" do
    n = News.in_portal(portal).published.find(:all)[0]
    assert_not_nil n
    go_to "/noticias/show/#{n.id}", 'noticias/show'
    assert_cache_exists "/common/noticias/show/_latest_by_cat_#{n.main_category.id}"
    delete_content n
    assert_cache_dont_exist "/common/noticias/show/_latest_by_cat_#{n.main_category.id}"
  end

  test "should clear authorship box" do
    panzer = User.find(2)
    n = News.in_portal(portal).published.find(:all, :include => :user)[0]
    assert_not_nil n
    assert n.user_id != panzer.id
    go_to "/noticias/show/#{n.id}", 'noticias/show'
    assert @response.body.include?(
        "por <a class=\"content\" href=\"http://test.host/miembros/superadmin" +
        "\">superadmin</a>")

    n.change_authorship(panzer, User.find(1))

    go_to "/noticias/show/#{n.id}", 'noticias/show'
    assert @response.body.include?(
        "por <a class=\"content\" href=\"http://test.host/miembros/panzer\">" +
        "panzer</a>")
  end

  # MAIN
  test "should_clear_cache_on_main_after_publishing_news" do
    n = News.in_portal(portal).pending.find(:all)[0]
    assert_not_nil n
    go_to '/noticias', 'noticias/index'
    assert_cache_exists "#{portal.code}/noticias/index/page_"
    publish_content n
    assert_cache_dont_exist "#{portal.code}/noticias/index/page_"
  end

  test "should_clear_cache_on_main_after_unpublishing_news" do
    n = News.in_portal(portal).published.find(:all)[0]
    assert_not_nil n
    go_to '/noticias', 'noticias/index'
    assert_cache_exists "#{portal.code}/noticias/index/page_"
    delete_content n
    assert_cache_dont_exist "#{portal.code}/noticias/index/page_"
  end

  test "should_clear_cache_on_main_after_updating_news" do
    n = News.in_portal(portal).published.find(:all)[0]
    assert_not_nil n
    go_to '/noticias', 'noticias/index'
    assert_cache_exists "#{portal.code}/noticias/index/page_"
    n.update_attributes({:title => 'faksdjlajdslda'})
    assert_cache_dont_exist "#{portal.code}/noticias/index/page_"
  end

  # PORTAL
  test "should_clear_cache_on_portal_after_publishing_news" do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_publishing_news
  end

  test "should_clear_cache_on_portal_after_unpublishing_news" do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_unpublishing_news
  end

  test "should_clear_cache_on_portal_after_updating_news" do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_updating_news
  end

  # CLAN
  def atest_should_clear_cache_on_clans_portal_after_publishing_news
    setup_clan_skin
    faction_host ClansPortal.find_by_code('mapaches')
    test_should_clear_cache_on_main_after_publishing_news
  end

  def atest_should_clear_cache_on_clans_portal_after_unpublishing_news
    setup_clan_skin
    faction_host ClansPortal.find_by_code('mapaches')
    test_should_clear_cache_on_main_after_unpublishing_news
  end

  def atest_should_clear_cache_on_clans_portal_after_updating_news
    setup_clan_skin
    # puts ClansPortal.find_by_code('mapaches').skin_id
    faction_host ClansPortal.find_by_code('mapaches')
    # puts ClansPortal.find_by_code('mapaches').skin_id
    test_should_clear_cache_on_main_after_updating_news
  end

  #test "should_clear_cache_on_clans_portal_after_rating_news" do
  #  setup_clan_skin
  #  faction_host ClansPortal.find_by_code('mapaches')
  #  test_should_clear_cache_on_main_after_rating_news
  # end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
