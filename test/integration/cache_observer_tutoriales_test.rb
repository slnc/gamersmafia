require File.dirname(__FILE__) + '/../test_helper'


class CacheObserverTutorialesTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  def test_should_clear_tutoriales_index_index_after_creating_a_new_category
    get '/tutoriales'
    assert_cache_exists '/gm/tutoriales/index/folders'
    @tc = Term.create({:name => 'foocat', :slug => 'codecot'})
    assert_cache_exists '/gm/tutoriales/index/folders'
    @tcc = @tc.children.create(:name => 'tutoriales del fin der mundo', :taxonomy => 'TutorialsCategory')
    assert_cache_dont_exist '/gm/tutoriales/index/folders'
  end
  
  def test_should_clear_tutoriales_index_index_after_updating_a_category
    test_should_clear_tutoriales_index_index_after_creating_a_new_category
    get '/tutoriales'
    assert_cache_exists '/gm/tutoriales/index/folders'
    @tcc.save
    assert_cache_dont_exist '/gm/tutoriales/index/folders'
  end
  
  def test_should_clear_tutoriales_index_index_after_deleting_a_category
    test_should_clear_tutoriales_index_index_after_creating_a_new_category
    get '/tutoriales'
    assert_cache_exists '/gm/tutoriales/index/folders'
    @tcc.destroy
    assert_cache_dont_exist '/gm/tutoriales/index/folders'
  end
  
  def test_should_clear_tutoriales_forums_list_after_creating_a_subcategory
    test_should_clear_tutoriales_index_index_after_creating_a_new_category
    get "/tutoriales/#{@tc.id}"
    assert_response :success
    assert_cache_exists "/common/tutoriales/index/folders_#{@tc.id}"
    @tc_child = @tc.children.create({:name => 'subfoocat', :slug => 'subcodecot', :taxonomy => 'TutorialsCategory'})
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
    tut = Tutorial.find(:published, :limit => 1).first
    fcat = tut.main_category
    assert !fcat.nil?
    get "/tutoriales/#{fcat.id}"
    assert_response :success
    assert_cache_exists "/common/tutoriales/index/tutorials_#{fcat.id}/page_"
    tcat2 = Term.find(:first, :conditions => ["root_id <> ? AND taxonomy = 'TutorialsCategory'", fcat.root.id])
    tut.categories_terms_ids = [tcat2.id, 'TutorialsCategory']
    assert_equal tcat2.id, tut.main_category.id
    assert_cache_dont_exist "/common/tutoriales/index/tutorials_#{fcat.id}/page_"
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end