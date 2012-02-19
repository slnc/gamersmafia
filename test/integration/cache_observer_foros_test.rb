require "#{File.dirname(__FILE__)}/../test_helper"

class CacheObserverForosTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  test "should_clear_foros_index_index_after_creating_a_new_category" do
    get '/foros'
    assert_response :success
    assert_cache_exists '/gm/foros/index/index'
    @rt = Term.single_toplevel(:slug => 'gm')
    @tc = @rt.children.create({:name => 'foocat', :taxonomy => 'TopicsCategory'})
    assert_cache_dont_exist '/gm/foros/index/index'
  end

  test "should_clear_foros_index_index_after_updating_a_category" do
    test_should_clear_foros_index_index_after_creating_a_new_category
    get '/foros'
    assert_response :success, @response.body
    assert_cache_exists '/gm/foros/index/index'
    @tc.save
    assert_cache_dont_exist '/gm/foros/index/index'
  end

  test "should_clear_foros_index_index_after_deleting_a_category" do
    test_should_clear_foros_index_index_after_creating_a_new_category
    get '/foros'
    assert_response :success, @response.body
    assert_cache_exists '/gm/foros/index/index'
    @tc.destroy
    assert_cache_dont_exist '/gm/foros/index/index'
  end

  test "should_clear_foros_forums_list_after_creating_a_subcategory" do
    test_should_clear_foros_index_index_after_creating_a_new_category
    get "/foros/forum/#{@tc.id}"
    assert_response :success, @response.body
    assert_cache_exists "/common/foros/_forums_list/#{@tc.id}"
    @tc_child = @tc.children.create({:name => 'subfoocat', :slug => 'subcodecot'})
    assert_cache_dont_exist "/common/foros/_forums_list/#{@tc.id}"
  end

  test "should_clear_foros_forums_list_after_updating_a_subcategory" do
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

  test "should_clear_foros_forums_list_after_destroying_a_subcategory" do
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
