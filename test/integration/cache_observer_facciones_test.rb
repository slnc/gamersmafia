require 'test_helper'

class CacheObserverFaccionesTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  test "should_clear_faction_user_ratios_graph_after_new_member_joining" do
    Factions::user_joins_faction(User.find(2), 1)
    link = "/cache/graphs/faction_users_ratios/#{Time.now.strftime('%Y%m%d')}/1.png"
    graph_file = "#{Rails.root}/public#{link}"
    File.unlink(graph_file) if File.exists?(graph_file)
    get link
    assert_response :redirect
    assert_equal true, File.exists?(graph_file)
    u = User.find(1)
    (u.faction_id = nil && u.save) if u.faction_id
    Factions::user_joins_faction(u, 1)
    assert_equal 1, u.faction_id
    assert_equal false, File.exists?(graph_file)
    get link
    assert_response :redirect
    assert_equal true, File.exists?(graph_file)
    Factions::user_joins_faction(u, nil)
    assert_equal false, File.exists?(graph_file)
  end

  test "should_clear_list_cache_index_on_user_joining_a_faction" do
    @u = User.find(1)
    go_to '/facciones', 'facciones/list'
    assert_cache_exists 'common/facciones/list_'
    Factions::user_joins_faction(@u, 1)
    assert_cache_dont_exist 'common/facciones/list_'
  end

  test "should_clear_list_cache_index_on_user_leaving_a_faction" do
    test_should_clear_list_cache_index_on_user_joining_a_faction
    go_to '/facciones', 'facciones/list'
    assert_cache_exists 'common/facciones/list_'
    Factions::user_joins_faction(@u, nil)
    assert_cache_dont_exist 'common/facciones/list_'
  end

  test "should_clear_show_cache_stats_of_new_faction_on_user_joining_a_faction" do
    @u = User.find(1)
    assert_nil @u.faction_id
    host! "#{FactionsPortal.find(1).code}.#{App.domain}"
    go_to '/faccion', 'faccion/index'
    assert_cache_exists "/common/facciones/#{Time.now.strftime('%Y%m%d')}/stats/1"
    Factions::user_joins_faction(@u, 1)
    assert_cache_dont_exist "/common/facciones/#{Time.now.strftime('%Y%m%d')}/stats/1"
  end

  test "should_clear_show_cache_stats_of_old_faction_on_user_joining_a_faction" do
    test_should_clear_show_cache_stats_of_new_faction_on_user_joining_a_faction
    Factions::user_joins_faction(@u, nil)
    assert_cache_dont_exist "/common/facciones/#{Time.now.strftime('%Y%m%d')}/stats/1"
  end

  test "should_clear_show_cache_last_joined_of_new_faction_on_user_joining_a_faction" do
    @u = User.find(1)
    assert_nil @u.faction_id
    host! "#{FactionsPortal.find(1).code}.#{App.domain}"
    go_to '/faccion', 'faccion/index'
    assert_cache_exists "/common/facciones/1/last_joined"
    Factions::user_joins_faction(@u, 1)
    assert_cache_dont_exist "/common/facciones/1/last_joined"
  end


  test "should_clear_miembros_cache_members_of_new_faction_on_user_joining_a_faction" do
    @u = User.find(1)
    assert_nil @u.faction_id
    host! "#{FactionsPortal.find(1).code}.#{App.domain}"
    go_to '/faccion/miembros', 'faccion/miembros'
    assert_cache_exists "/common/facciones/miembros/1/page_"
    Factions::user_joins_faction(@u, 1)
    assert_cache_dont_exist "/common/facciones/miembros/1/page_"
  end

  test "should_clear_miembros_cache_members_of_old_faction_on_user_joining_a_faction" do
    test_should_clear_show_cache_stats_of_new_faction_on_user_joining_a_faction
    host! "#{FactionsPortal.find(1).code}.#{App.domain}"
    go_to '/faccion/miembros', 'faccion/miembros'
    assert_cache_exists "/common/facciones/miembros/1/page_"
    Factions::user_joins_faction(@u, nil)
    assert_cache_dont_exist "/common/facciones/miembros/1/page_"
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
