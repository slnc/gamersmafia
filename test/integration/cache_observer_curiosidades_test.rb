require 'test_helper'


class CacheObservercuriosidadesTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  # MAIN
  test "should_clear_cache_on_main_after_publishing_funthing" do
    n = Funthing.find(:pending)[0]
    assert_not_nil n
    go_to '/curiosidades', 'curiosidades/index'
    assert_cache_exists "common/curiosidades/index/page_"
    publish_content n
    assert_cache_dont_exist "curiosidades/curiosidades/index/page_"
  end

  test "should_clear_cache_on_main_after_unpublishing_funthing" do
    n = Funthing.find(:published)[0]
    assert_not_nil n
    go_to '/curiosidades', 'curiosidades/index'
    assert_cache_exists "common/curiosidades/index/page_"
    delete_content n
    assert_cache_dont_exist "common/curiosidades/index/page_"
  end

  test "should_clear_cache_on_main_after_updating_funthing" do
    n = Funthing.find(:published)[0]
    assert_not_nil n
    go_to '/curiosidades', 'curiosidades/index'
    assert_cache_exists "common/curiosidades/index/page_"
    n.update_attributes({:title => 'faksdjlajdslda'})
    assert_cache_dont_exist "common/curiosidades/index/page_"
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
