require 'test_helper'


class CacheObserverEntrevistasTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    faction_host Portal.find_by_code('ut')
    # host! App.domain
  end

  # MAIN
  test "should_clear_cache_on_main_after_publishing_interview" do
    n = portal.interview.find(:pending)[0]
    assert_not_nil n
    go_to '/entrevistas', 'entrevistas/index'
    assert_cache_exists "#{portal.code}/entrevistas/index/page_"
    publish_content n
    assert_cache_dont_exist "#{portal.code}/entrevistas/index/page_"
  end

  test "should_clear_cache_on_main_after_unpublishing_interview" do
    n = portal.interview.find(:published)[0]
    assert_not_nil n
    go_to '/entrevistas', 'entrevistas/index'
    assert_cache_exists "#{portal.code}/entrevistas/index/page_"
    delete_content n
    assert_cache_dont_exist "#{portal.code}/entrevistas/index/page_"
  end

  test "should_clear_cache_on_main_after_updating_interview" do
    n = portal.interview.find(:published)[0]
    assert_not_nil n
    go_to '/entrevistas', 'entrevistas/index'
    assert_cache_exists "#{portal.code}/entrevistas/index/page_"
    n.update_attributes({:title => 'faksdjlajdslda'})
    assert_cache_dont_exist "#{portal.code}/entrevistas/index/page_"
  end

  test "should_clear_cache_others_by_author_on_main_after_publishing_a_new_interview" do
    n = portal.interview.find(:published)[0]
    assert_not_nil n
    go_to "/entrevistas/show/#{n.id}", 'entrevistas/show'
    assert_cache_exists "#{portal.code}/entrevistas/show/latest_by_author_#{n.user_id}"
    n2 = portal.interview.find(:pending, :conditions => ['contents.user_id = ?', n.user_id])[0]
    publish_content n2
    assert_cache_dont_exist "#{portal.code}/entrevistas/show/latest_by_author_#{n.user_id}"
  end


  # PORTAL
  test "should_clear_cache_on_portal_after_publishing_interview" do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_publishing_interview
  end

  test "should_clear_cache_on_portal_after_unpublishing_interview" do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_unpublishing_interview
  end

  test "should_clear_cache_on_portal_after_updating_interview" do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_updating_interview
  end

  test "should_clear_cache_on_portal_after_rating_interview" do
    faction_host FactionsPortal.find_by_code('ut')
    test_should_clear_cache_on_main_after_rating_interview
  end

  test "should_clear_cache_on_portal_after_rating_interview" do
    faction_host FactionsPortal.find_by_code('ut')
    # TODO hack temporal
    Interview.find(:published).each do |c|
      uniq = c.unique_content
      uniq.url = uniq.url.gsub('http://gamersmafia.dev', 'http://ut.gamersmafia.dev')
      uniq.save
    end
    test_should_clear_cache_others_by_author_on_main_after_publishing_a_new_interview
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
