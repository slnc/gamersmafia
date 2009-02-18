require "#{File.dirname(__FILE__)}/../test_helper"

class CacheObserverForosTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end
  
  def test_should_clear_foros_index_index_after_creating_a_new_category
    get '/foros'
    assert_cache_exists '/gm/foros/index/index'
    @tc = TopicsCategory.create({:name => 'foocat', :code => 'codecot'})
    assert_cache_dont_exist '/gm/foros/index/index'
  end
  
  def test_should_clear_foros_index_index_after_updating_a_category
    test_should_clear_foros_index_index_after_creating_a_new_category
    get '/foros'
    assert_cache_exists '/gm/foros/index/index'
    TopicsCategory.find_by_code('codecot').save
    assert_cache_dont_exist '/gm/foros/index/index'
  end
  
  def test_should_clear_foros_index_index_after_deleting_a_category
    test_should_clear_foros_index_index_after_creating_a_new_category
    get '/foros'
    assert_cache_exists '/gm/foros/index/index'
    TopicsCategory.find_by_code('codecot').destroy
    assert_cache_dont_exist '/gm/foros/index/index'
  end
  
  def test_should_clear_foros_forums_list_after_creating_a_subcategory
    test_should_clear_foros_index_index_after_creating_a_new_category
    get "/foros/forum/#{@tc.id}"
    assert_response :success, @response.body
    assert_cache_exists "/common/foros/_forums_list/#{@tc.id}"
    @tc_child = @tc.children.create({:name => 'subfoocat', :code => 'subcodecot'})
    assert_cache_dont_exist "/common/foros/_forums_list/#{@tc.id}"
  end
  
  def test_should_clear_foros_forums_list_after_updating_a_subcategory
    test_should_clear_foros_forums_list_after_creating_a_subcategory
    get "/foros/forum/#{@tc_child.id}"
    assert_response :success
    get "/foros/forum/#{@tc.id}"
    assert_response :success
    assert_cache_exists "/common/foros/_forums_list/#{@tc.id}"
    assert_cache_exists "/common/foros/_forums_list/#{@tc_child.id}"
    @tc_child.save
    assert_cache_dont_exist "/common/foros/_forums_list/#{@tc.id}"
    assert_cache_dont_exist "/common/foros/_forums_list/#{@tc_child.id}"
  end
  
  def test_should_clear_foros_forums_list_after_destroying_a_subcategory
    test_should_clear_foros_forums_list_after_creating_a_subcategory
    get "/foros/forum/#{@tc_child.id}"
    assert_response :success
    get "/foros/forum/#{@tc.id}"
    assert_response :success
    assert_cache_exists "/common/foros/_forums_list/#{@tc.id}"
    assert_cache_exists "/common/foros/_forums_list/#{@tc_child.id}"
    @tc_child.destroy
    assert_cache_dont_exist "/common/foros/_forums_list/#{@tc.id}"
    assert_cache_dont_exist "/common/foros/_forums_list/#{@tc_child.id}"
  end
  
  def teardown
    ActionController::Base.perform_caching             = false
  end
end
