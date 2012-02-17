require 'test_helper'


class CacheObserverDescargasTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  # GLOBAL NAVIGATOR
  test "should_delete_subcategories_cache_after_creating_download" do
    # creation
    c1 = Term.create({:slug => 'c1', :name => 'foo1'})
    c1.reload
    assert_not_nil c1
    c2 = c1.children.create({:taxonomy => 'DownloadsCategory', :slug => 'c2', :name => 'foo1'})
    c2.reload
    assert_not_nil c2
    d = Download.create(:user_id => 1, :title => 'xxxfootapang', :terms => c2.id)
    assert_not_nil d

    go_to_downloads_category(c1)
    assert_cache_exists "common/descargas/index/folders_#{c1.id}"

    go_to_downloads_category(c2)
    assert_cache_exists "common/descargas/index/downloads_#{c2.id}/page_"

    #
    d.change_state(Cms::PUBLISHED, User.find(1))
    assert_cache_dont_exist "common/descargas/index/downloads_#{c2.id}/page_"
    assert_cache_dont_exist "common/descargas/index/folders_#{c1.id}"
    @d = d
    @c1 = c1
    @c2 = c2
  end

  test "should_delete_subcategories_cache_after_downloading_download" do
    test_should_delete_subcategories_cache_after_creating_download

    go_to_downloads_category(@c1)
    assert_cache_exists "common/descargas/index/downloads_#{@c1.id}/page_"
    assert_cache_exists "common/descargas/index/most_downloaded_#{@c1.root_id}"

    go_to_downloads_category(@c2)
    assert_cache_exists "common/descargas/index/downloads_#{@c2.id}/page_"

    # download
    get "/descargas/download/#{@d.id}"
    assert_cache_dont_exist "common/descargas/index/downloads_#{@c2.id}/page_"
    assert_cache_dont_exist "common/descargas/index/most_downloaded_#{@c1.root_id}"
  end

  def go_to_downloads_category(c)
    get "/descargas/#{c.id}"
    assert_response :success, response.body
    assert_template 'descargas/index'
  end


  test "should_clear_descargas_index_index_after_creating_a_new_category" do
    get '/descargas'
    assert_response :success, response.body
    assert_cache_exists '/gm/descargas/index/folders'
    rt = Term.single_toplevel(:slug => 'gm')
    @tc = rt.children.create({:name => 'foocat', :taxonomy => 'DownloadsCategory'})
    assert_cache_dont_exist '/gm/descargas/index/folders'
  end

  test "should_clear_descargas_index_index_after_updating_a_category" do
    test_should_clear_descargas_index_index_after_creating_a_new_category
    get '/descargas'
    assert_response :success
    assert_cache_exists '/gm/descargas/index/folders'
    @tc.save
    assert_cache_dont_exist '/gm/descargas/index/folders'
  end

  test "should_clear_descargas_index_index_after_deleting_a_category" do
    test_should_clear_descargas_index_index_after_creating_a_new_category
    get '/descargas'
    assert_response :success
    assert_cache_exists '/gm/descargas/index/folders'
    @tc.destroy
    assert_cache_dont_exist '/gm/descargas/index/folders'
  end

  test "should_clear_descargas_forums_list_after_creating_a_subcategory" do
    test_should_clear_descargas_index_index_after_creating_a_new_category
    get "/descargas/#{@tc.id}"
    assert_response :success, response.body
    assert_cache_exists "/common/descargas/index/folders_#{@tc.id}"
    @tc_child = @tc.children.create(:name => 'subfoocat')
    assert_cache_dont_exist "/common/descargas/index/folders_#{@tc.id}"
  end

  test "should_clear_descargas_forums_list_after_updating_a_subcategory" do
    test_should_clear_descargas_forums_list_after_creating_a_subcategory
    get "/descargas/#{@tc_child.id}"
    assert_response :success, response.body
    get "/descargas/#{@tc.id}"
    assert_response :success, response.body
    assert_cache_exists "/common/descargas/index/folders_#{@tc.id}"
    assert_cache_exists "/common/descargas/index/folders_#{@tc_child.id}"
    @tc_child.save
    assert_cache_dont_exist "/common/descargas/index/folders_#{@tc.id}"
    assert_cache_dont_exist "/common/descargas/index/folders_#{@tc_child.id}"
  end

  test "should_clear_descargas_forums_list_after_destroying_a_subcategory" do
    test_should_clear_descargas_forums_list_after_creating_a_subcategory
    get "/descargas/#{@tc_child.id}"
    assert_response :success
    get "/descargas/#{@tc.id}"
    assert_response :success
    assert_cache_exists "/common/descargas/index/folders_#{@tc.id}"
    assert_cache_exists "/common/descargas/index/folders_#{@tc_child.id}"
    @tc_child.destroy
    assert_cache_dont_exist "/common/descargas/index/folders_#{@tc.id}"
    assert_cache_dont_exist "/common/descargas/index/folders_#{@tc_child.id}"
  end

  test "should_clear_descargas_essential_after_saving_a_download_with_its_essential_field_changed" do
    d = Download.published.find(:all, :limit => 1)[0]
    assert_not_nil d
    get "/descargas/#{d.main_category.id}"
    get "/descargas/#{d.main_category.id}"
    assert_response :success
    assert_cache_exists "/common/descargas/index/essential2_#{d.main_category.root_id}"
    d.essential = true
    d.save
    assert_cache_dont_exist "/common/descargas/index/essential2_#{d.main_category.root_id}"
  end


  test "should_clear_tutoriales_index_of_previous_category_when_moving_to_new_category" do
    tut = Download.find(1)
    mc = tut.main_category
    get "/descargas/#{mc.id}"
    assert_response :success, response.body
    assert_cache_exists "/common/descargas/index/downloads_#{mc.id}/page_"
    mc.unlink(tut.unique_content)
    assert_cache_dont_exist "/common/descargas/index/downloads_#{mc.id}/page_"
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
