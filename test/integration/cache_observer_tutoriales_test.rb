require File.dirname(__FILE__) + '/../test_helper'


class CacheObserverTutorialesTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  def test_should_clear_tutoriales_index_index_after_creating_a_new_category
    get '/tutoriales'
    assert_cache_exists '/gm/tutoriales/index/folders'
    @tc = TutorialsCategory.create({:name => 'foocat', :code => 'codecot'})
    assert_cache_dont_exist '/gm/tutoriales/index/folders'
  end
  
  def test_should_clear_tutoriales_index_index_after_updating_a_category
    test_should_clear_tutoriales_index_index_after_creating_a_new_category
    get '/tutoriales'
    assert_cache_exists '/gm/tutoriales/index/folders'
    TutorialsCategory.find_by_code('codecot').save
    assert_cache_dont_exist '/gm/tutoriales/index/folders'
  end
  
  def test_should_clear_tutoriales_index_index_after_deleting_a_category
    test_should_clear_tutoriales_index_index_after_creating_a_new_category
    get '/tutoriales'
    assert_cache_exists '/gm/tutoriales/index/folders'
    TutorialsCategory.find_by_code('codecot').destroy
    assert_cache_dont_exist '/gm/tutoriales/index/folders'
  end
  
  def test_should_clear_tutoriales_forums_list_after_creating_a_subcategory
    test_should_clear_tutoriales_index_index_after_creating_a_new_category
    get "/tutoriales/#{@tc.id}"
    assert_response :success
    assert_cache_exists "/common/tutoriales/index/folders_#{@tc.id}"
    @tc_child = @tc.children.create({:name => 'subfoocat', :code => 'subcodecot'})
    assert_cache_dont_exist "/common/tutoriales/index/folders_#{@tc.id}"
  end
  
  def test_should_clear_tutoriales_forums_list_after_updating_a_subcategory
    test_should_clear_tutoriales_forums_list_after_creating_a_subcategory
    get "/tutoriales/#{@tc_child.id}"
    assert_response :success
    get "/tutoriales/#{@tc.id}"
    assert_response :success
    assert_cache_exists "/common/tutoriales/index/folders_#{@tc.id}"
    assert_cache_exists "/common/tutoriales/index/folders_#{@tc_child.id}"
    @tc_child.save
    assert_cache_dont_exist "/common/tutoriales/index/folders_#{@tc.id}"
    assert_cache_dont_exist "/common/tutoriales/index/folders_#{@tc_child.id}"
  end
  
  def test_should_clear_tutoriales_forums_list_after_destroying_a_subcategory
    test_should_clear_tutoriales_forums_list_after_creating_a_subcategory
    get "/tutoriales/#{@tc_child.id}"
    assert_response :success
    get "/tutoriales/#{@tc.id}"
    assert_response :success
    assert_cache_exists "/common/tutoriales/index/folders_#{@tc.id}"
    assert_cache_exists "/common/tutoriales/index/folders_#{@tc_child.id}"
    @tc_child.destroy
    assert_cache_dont_exist "/common/tutoriales/index/folders_#{@tc.id}"
    assert_cache_dont_exist "/common/tutoriales/index/folders_#{@tc_child.id}"
  end
  
  def test_should_clear_tutoriales_index_of_previous_category_when_moving_to_new_category
    get "/tutoriales/1"
    assert_response :success
    assert_cache_exists "/common/tutoriales/index/tutorials_1/page_"
    tut = Tutorial.find(1)
    assert_equal true, tut.update_attributes({:tutorials_category_id => 5})
    assert_cache_dont_exist "/common/tutoriales/index/tutorials_1/page_"
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end