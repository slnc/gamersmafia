require File.dirname(__FILE__) + '/../test_helper'


class CacheObserverEncuestasTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  # MAIN
  def test_should_clear_cache_on_main_after_publishing_poll
    n = portal.poll.find(:pending)[0]
    assert_not_nil n
    go_to '/encuestas', 'encuestas/index'
    assert_cache_exists "#{portal.code}/encuestas/index/page_"
    publish_content n
    assert_cache_dont_exist "#{portal.code}/encuestas/index/page_"
  end

  def test_should_clear_cache_on_main_after_unpublishing_poll
    n = portal.poll.find(:published)[0]
    assert_not_nil n
    go_to '/encuestas', 'encuestas/index'
    assert_cache_exists "#{portal.code}/encuestas/index/page_"
    delete_content n
    assert_cache_dont_exist "#{portal.code}/encuestas/index/page_"
  end

  def test_should_clear_cache_on_main_after_updating_poll
    n = portal.poll.find(:published)[0]
    assert_not_nil n
    go_to '/encuestas', 'encuestas/index'
    assert_cache_exists "#{portal.code}/encuestas/index/page_"
    n.update_attributes({:title => 'faksdjlajdslda'})
    assert_cache_dont_exist "#{portal.code}/encuestas/index/page_"
  end

  def test_should_clear_cache_most_votes_on_main_after_voting
    n = portal.poll.find(:published)[0]
    assert_not_nil n
    go_to '/encuestas', 'encuestas/index'
    assert_cache_exists "#{portal.code}/encuestas/index/most_votes"
    post "/encuestas/vote/#{n.id}", { :poll_option => n.polls_options.find(:first).id }
    assert_response :redirect
    assert_cache_dont_exist "#{portal.code}/encuestas/index/most_votes"
  end


  # PORTAL
  def test_should_clear_cache_on_portal_after_publishing_poll
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_publishing_poll
  end

  def test_should_clear_cache_on_portal_after_unpublishing_poll
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_unpublishing_poll
  end

  def test_should_clear_cache_on_portal_after_updating_poll
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_updating_poll
  end

  def test_should_clear_cache_on_portal_after_voting_poll
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_most_votes_on_main_after_voting
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
