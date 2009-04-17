require 'test_helper'


class CacheObserverColumnasTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  # MAIN
  test "should_clear_cache_on_main_after_publishing_column" do
    n = portal.column.find(:pending)[0]
    assert_not_nil n
    go_to '/columnas', 'columnas/index'
    assert_cache_exists "#{portal.code}/columnas/index/page_"
    publish_content n
    assert_cache_dont_exist "#{portal.code}/columnas/index/page_"
  end

  test "should_clear_most_popular_authors_cache_on_main_after_changing_column_authorship" do
    go_to '/columnas', 'columnas/index'
    assert_cache_exists "gm/columnas/index/most_popular_authors_#{Time.now.to_i/(86400)}"
    n = Column.find(:published)[0]
    assert_not_nil n
    n.change_authorship(User.find(2), User.find(1))
    assert_equal 2, n.user_id
    assert_cache_dont_exist "gm/columnas/index/most_popular_authors_#{Time.now.to_i/(86400)}"
  end

  test "should_clear_cache_on_main_after_unpublishing_column" do
    n = portal.column.find(:published)[0]
    assert_not_nil n
    go_to '/columnas', 'columnas/index'
    assert_cache_exists "#{portal.code}/columnas/index/page_"
    delete_content n
    assert_cache_dont_exist "#{portal.code}/columnas/index/page_"
  end

  test "should_clear_cache_on_main_after_updating_column" do
    n = portal.column.find(:published)[0]
    assert_not_nil n
    go_to '/columnas', 'columnas/index'
    assert_cache_exists "#{portal.code}/columnas/index/page_"
    n.update_attributes({:title => 'faksdjlajdslda'})
    assert_cache_dont_exist "#{portal.code}/columnas/index/page_"
  end

  test "should_clear_cache_others_by_author_on_main_after_publishing_a_new_column" do
    pp = Portal.find_by_code('ut')
    faction_host pp
    n = pp.column.find(:published)[0]
    assert_not_nil n
    go_to "/columnas/show/#{n.id}", 'columnas/show'
    assert_cache_exists "#{pp.code}/columnas/show/latest_by_author_#{n.user_id}"
    n2 = pp.column.find(:pending, :conditions => ['contents.user_id = ?', n.user_id])[0]
    publish_content n2
    assert_cache_dont_exist "#{pp.code}/columnas/show/latest_by_author_#{n.user_id}"
  end


  # PORTAL
  test "should_clear_cache_on_portal_after_publishing_ faction column" do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_publishing_column
  end

  test "should_clear_cache_on_portal_after_unpublishing_faction column" do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_unpublishing_column
  end

  test "should_clear_cache_on_portal_after_updating_columnfaction " do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_updating_column
  end

  test "should_clear_cache_on_portal_after_rating_columnfaction " do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_rating_column
  end

  test "should_clear_cache_on_portal_after_rating_columnfaction 2" do
    faction_host FactionsPortal.find_by_code('ut')
    # TODO hack temporal hasta que las referencias desde inet se hayan reducido
    Column.find(:published).each do |c|
      uniq = c.unique_content
      uniq.url = uniq.url.gsub('http://gamersmafia.dev', 'http://ut.gamersmafia.dev')
      uniq.save
    end
    test_should_clear_cache_others_by_author_on_main_after_publishing_a_new_column
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
