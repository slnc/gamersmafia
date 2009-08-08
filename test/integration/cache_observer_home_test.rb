require 'test_helper'

class CacheObserverHomeTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end
  
  #test "should_clear_top_factions_when_someone_joins_a_faction" do
  # go_to_index
  #assert_cache_exists '/common/home/index/factions_stats'
  #Factions::user_joins_faction(User.find(1), 1)
  #assert_cache_dont_exist '/common/home/index/factions_stats'
  #end
  
  #  test "should_clear_competitions_box_when_new_match_is_completed" do
  #  flunk 'todo'
  #    go_to_index
  #    assert_cache_exists '/common/home/index/factions_stats'
  #    Factions::user_joins_faction(User.find(1), nil)
  #    assert_cache_dont_exist '/common/home/index/factions_stats'
  #  end
  
  #  test "should_clear_top_factions_when_someone_leaves_a_faction" do
  #    test_should_clear_top_factions_when_someone_joins_a_faction
  #go_to_index
  #assert_cache_exists '/common/home/index/factions_stats'
  #Factions::user_joins_faction(User.find(1), nil)
  #assert_cache_dont_exist '/common/home/index/factions_stats'
  #end
  test "should clear factions home box on factions update" do
    port = Portal.factions.find(:first)
    assert port
    host! "#{port.code}.#{App.domain}"
    get '/'
    assert_response :success
    assert_cache_exists "/common/facciones/#{Time.now.strftime('%Y%m%d')}/stats/2_#{port.factions[0].id}"
    assert port.factions[0].update_attributes(:building_top => fixture_file_upload('files/babe.jpg'))
    assert_cache_dont_exist "/common/facciones/#{Time.now.strftime('%Y%m%d')}/stats/2_#{port.factions[0].id}"
  end
  
  test "should_clear_events_box_when_someone_joins_an_event" do
    e = Event.new({:user_id => 1, :title => 'evento tal cual', :terms => 1, :starts_on => 2.days.ago, :ends_on => 3.days.since})
    assert_equal true, e.save
    e.change_state(Cms::PUBLISHED, User.find(1))
    assert_equal true, e.is_public?
    go_to_index
    assert_cache_exists "gm/home/index/eventos/#{Time.now.strftime('%Y%m%d')}"
    e.member_join(User.find(1))
    assert_cache_dont_exist "gm/home/index/eventos/#{Time.now.strftime('%Y%m%d')}"
  end
  
  test "should_clear_events_box_when_someone_leaves_an_event" do
    test_should_clear_events_box_when_someone_joins_an_event
    go_to_index
    assert_cache_exists "gm/home/index/eventos/#{Time.now.strftime('%Y%m%d')}"
    e = Event.find(:first, :order => 'id DESC')
    assert_not_nil e
    e.member_leave(User.find(1))
    assert_cache_dont_exist "gm/home/index/eventos/#{Time.now.strftime('%Y%m%d')}"
  end
  
  
  def go_to_index
    get '/'
    assert_response :success, response.body
    assert_template 'home/gm'
  end
  
  #  test "should_clear_competitions_box_on_main_when_competitions_match_is_confirmed" do
  #  end
  
  #  test "should_clear_competitions_box_on_portal_when_competitions_match_is_confirmed" do
  #  end
  
  test "should_clear_funthings_cache_after_publishing_funthing" do
    host! App.domain_bazar
    n = Funthing.find(:pending)[0]
    assert_not_nil n
    get '/'
    assert_response :success, response.body
    assert_template 'home/bazar'
    assert_cache_exists "common/home/index/curiosidades2"
    publish_content n
    assert_cache_dont_exist "common/home/index/curiosidades2"
  end
  
  test "should_clear_funthings_cache_after_unpublishing_funthing" do
    host! App.domain_bazar
    n = Funthing.find(:published)[0]
    assert_not_nil n
    get '/'
    assert_response :success, response.body
    assert_template 'home/bazar'
    assert_cache_exists "common/home/index/curiosidades2"
    delete_content n
    assert_cache_dont_exist "common/home/index/curiosidades2"
  end
  
  test "should_clear_funthings_cache_after_commenting_funthing" do
    host! App.domain_bazar
    n = Funthing.find(:published)[0]
    assert_not_nil n
    sym_login 'superadmin', 'lalala'
    get '/'
    assert_response :success, response.body
    assert_template 'home/bazar'
    assert_cache_exists "common/home/index/curiosidades2"
    post_comment_on n
    assert_cache_dont_exist "common/home/index/curiosidades2"
  end
  
  
  test "should_clear_daily_image_if_current_potd_becomes_unavailable" do
    go_to_index
    go_to_index # dos veces por si no hay potd elegida
    d = Time.now
    assert_cache_exists "gm/home/index/potd_#{d.strftime('%Y%m%d')}"
    
    # copypasted de potd_test
    im = Image.find(:first, :conditions => "approved_by_user_id is not null and state = #{Cms::PUBLISHED}")
    assert_not_nil im
    potd = Potd.new({:date => Time.now, :image_id => im.id})
    assert_equal true, potd.save
    
    im.change_state(Cms::DELETED, User.find(1))
    assert_equal false, im.is_public?
    assert_nil Potd.find_by_id(potd.id)
    # end copypaste
    
    assert_cache_dont_exist "gm/home/index/potd_#{d.strftime('%Y%m%d')}"
  end
  
  test "should_clear_last_blogs_when_new_blogentry_is_created" do
    go_to_index
    assert_cache_exists 'common/home/index/blogentries'
    be_count = Blogentry.count
    Blogentry.create({:user_id => 1, :title => 'foo', :main => 'bar', :state => Cms::PUBLISHED})
    assert_equal be_count + 1, Blogentry.count
    assert_cache_dont_exist 'common/home/index/blogentries'
  end
  
  test "should_clear_last_blogs_when_new_blogentry_is_deleted" do
    test_should_clear_last_blogs_when_new_blogentry_is_created
    go_to_index
    assert_cache_exists 'common/home/index/blogentries'
    be = Blogentry.find(:first, :order => 'id DESC')
    be.destroy
    assert_nil Blogentry.find_by_id(be.id)
    assert_cache_dont_exist 'common/home/index/blogentries'
  end
  
  test "should_clear_last_blogs_when_new_blogentry_is_updated" do
    test_should_clear_last_blogs_when_new_blogentry_is_created
    go_to_index
    assert_cache_exists 'common/home/index/blogentries'
    be = Blogentry.find(:first, :order => 'id DESC')
    assert be.update_attributes({:title => 'foofito'})
    assert_cache_dont_exist 'common/home/index/blogentries'
  end
  
  test "should_clear_last_news_of_district" do
    n = News.new(:title => 'Noticia 1', :description => 'sumario', :user_id => 1)
    assert n.save
    assert Term.single_toplevel(:slug => 'anime').link(n.unique_content)
    host! "anime.#{App.domain}"
    get '/'
    assert_response :success, @response.body
    assert_cache_exists "/anime/home/index/news2"
    publish_content n
    assert_cache_dont_exist "/anime/home/index/news2"
  end
  
  def teardown
    ActionController::Base.perform_caching             = false
  end
end
