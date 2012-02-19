require 'test_helper'


class CacheObserverReviewsTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  test "should_clear_most_popular_authors_cache_on_main_after_changing_column_authorship" do
    go_to '/reviews', 'reviews/index'
    assert_cache_exists "gm/reviews/index/most_popular_authors_#{Time.now.to_i/(86400)}"
    n = Review.published.find(:all)[0]
    assert_not_nil n
    n.change_authorship(User.find(2), User.find(1))
    assert_equal 2, n.user_id
    assert_cache_dont_exist "gm/reviews/index/most_popular_authors_#{Time.now.to_i/(86400)}"
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
