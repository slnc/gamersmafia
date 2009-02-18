require File.dirname(__FILE__) + '/../test_helper'


class CacheObserverApuestasTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! "arena.#{App.domain}"
  end

  # COMMON
  def test_should_clear_cache_latest_by_cat_after_publishing_news
    n = portal.bet.find(:published)[0]
    assert_not_nil n
    go_to "/apuestas/show/#{n.id}", 'apuestas/show'
    assert_cache_exists "/common/apuestas/show/latest_by_cat_#{n.bets_category_id}"
    delete_content n
    assert_cache_dont_exist "/common/apuestas/show/latest_by_cat_#{n.bets_category_id}"
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
