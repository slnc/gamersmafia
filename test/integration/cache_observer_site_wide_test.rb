require File.dirname(__FILE__) + '/../test_helper'

class CacheObserverSiteWideTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  def test_should_clear_last_commented_objects_cache_on_main_after_commenting
    sym_login 'superadmin', 'lalala'
    go_to '/'
    assert_cache_exists 'gm/site/last_commented_objects'
    assert_cache_exists 'gm/site/last_commented_objects_ids'
    post_comment_on News.find(:first, :conditions => "state = #{Cms::PUBLISHED}")
    assert_cache_dont_exist 'gm/site/last_commented_objects'
    assert_cache_dont_exist 'gm/site/last_commented_objects_ids'
  end

  def test_should_clear_last_commented_objects_cache_on_portal_after_commenting
    g1 = Game.find(1)
    # host! "#{g1.code}.#{App.domain}"
    faction_host Portal.find_by_code(g1.code)
    sym_login 'superadmin', 'lalala'
    go_to '/'
    assert_cache_exists "#{g1.code}/site/last_commented_objects"
    assert_cache_exists "#{g1.code}/site/last_commented_objects_ids"
    
    post_comment_on Blogentry.find(:first, :conditions => "state = #{Cms::PUBLISHED}")
    assert_cache_dont_exist "#{g1.code}/site/last_commented_objects"
    assert_cache_dont_exist "#{g1.code}/site/last_commented_objects_ids"
  end  
  
  def test_should_clear_lasttopics_box_when_deleting_a_topic
    sym_login 'superadmin', 'lalala'
    create_content(:topic, { :title => 'topico titulado 2', :main => 'contenido del topicotitulado 2'}, :categories_terms => [Term.find(:first, :conditions => "taxonomy = 'TopicsCategory'").id])
    topic = Topic.find(:first, :order => 'id DESC')
    post_comment_on topic
    go_to '/'
    assert_cache_exists 'gm/site/last_commented_objects'
    assert_cache_exists 'gm/site/last_commented_objects_ids'
    assert_cache_exists 'gm/home/index/topics'
    post "/foros/destroy/#{topic.id}"
    assert_cache_dont_exist 'gm/site/last_commented_objects'
    assert_cache_dont_exist 'gm/site/last_commented_objects_ids'
    assert_cache_dont_exist 'gm/home/index/topics'
  end

  def test_should_clear_lasttopics_box_when_deleting_a_content
    sym_login 'superadmin', 'lalala'
    create_content(:news, { :title => 'topico titulado 2', :description => 'contenido del topicotitulado 2', :state => Cms::PUBLISHED }, :root_terms => 1)
    news = News.find(:first, :order => 'id DESC')
    news.state = Cms::PUBLISHED
    news.save
    news.reload
    assert_equal Cms::PUBLISHED, news.state
    post_comment_on news
    go_to '/'
    assert_cache_exists 'gm/site/last_commented_objects'
    assert_cache_exists 'gm/site/last_commented_objects_ids'
    post "/noticias/destroy/#{news.id}"
    assert_cache_dont_exist 'gm/site/last_commented_objects'
    assert_cache_dont_exist 'gm/site/last_commented_objects_ids'
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
