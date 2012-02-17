require 'test_helper'


class CacheObserverEncuestasTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  # MAIN
  test "should_clear_cache_on_main_after_publishing_poll" do
    n = portal.poll.find(:pending)[0]
    # Term.single_toplevel(:slug => 'gm').poll.find(:pending).each { |poll| puts poll.title }
    assert_not_nil n
    go_to '/encuestas', 'encuestas/index'
    assert_response :success, @response.body
    assert_cache_exists "#{portal.code}/encuestas/index/page_"
    publish_content n
    assert_cache_dont_exist "#{portal.code}/encuestas/index/page_"
  end

  test "should_clear_cache_on_main_after_unpublishing_poll" do
    n = portal.poll.published.find(:all)[0]
    assert_not_nil n
    go_to '/encuestas', 'encuestas/index'
    assert_cache_exists "#{portal.code}/encuestas/index/page_"
    delete_content n
    assert_cache_dont_exist "#{portal.code}/encuestas/index/page_"
  end

  test "should_clear_cache_on_main_after_updating_poll" do
    n = portal.poll.published.find(:all)[0]
    assert_not_nil n
    go_to '/encuestas', 'encuestas/index'
    assert_cache_exists "#{portal.code}/encuestas/index/page_"
    n.update_attributes({:title => 'faksdjlajdslda'})
    assert_cache_dont_exist "#{portal.code}/encuestas/index/page_"
  end

  test "should_clear_cache_most_votes_on_main_after_voting" do
    n = portal.poll.published.find(:all)[0]
    assert_not_nil n
    go_to '/encuestas', 'encuestas/index'
    assert_cache_exists "#{portal.code}/encuestas/index/most_votes"
    post "/encuestas/vote/#{n.id}", { :poll_option => n.polls_options.find(:first).id }
    assert_response :redirect
    assert_cache_dont_exist "#{portal.code}/encuestas/index/most_votes"
  end


  # PORTAL
  test "should_clear_cache_on_portal_after_publishing_poll" do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_publishing_poll
  end

  test "should_clear_cache_on_portal_after_unpublishing_poll" do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_unpublishing_poll
  end

  test "should_clear_cache_on_portal_after_updating_poll" do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_updating_poll
  end

  test "should_clear_cache_on_portal_after_voting_poll" do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_most_votes_on_main_after_voting
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
