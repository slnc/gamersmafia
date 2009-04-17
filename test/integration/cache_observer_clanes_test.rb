require 'test_helper'

class CacheObserverClanesTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
    @portal = nil
  end
  
  def go_to_clanes
    get '/clanes'
    assert_response :success, @response.body
    assert_template 'clanes/index'
  end
  
  def test_should_clear_newest_box_on_main_when_new_clan_is_created
    go_to_clanes
    assert_cache_exists '/gm/clanes/index/newest'
    
    @c = Clan.new({:name => 'foomasters', :tag => 'tagm'})
    assert_equal true, @c.save, @c.errors.full_messages
    @c.games<< Game.find(1)
    assert_cache_dont_exist '/gm/clanes/index/newest'
  end
  
  def test_should_clear_newest_box_on_main_when_clan_is_deleted
    test_should_clear_newest_box_on_main_when_new_clan_is_created
    go_to_clanes
    assert_cache_exists '/gm/clanes/index/newest'
    @c.deleted = true
    @c.save
    assert_cache_dont_exist '/gm/clanes/index/newest'
  end
  
  def test_should_not_clear_newest_box_on_main_when_clan_changes_its_games_associations
    test_should_clear_newest_box_on_main_when_new_clan_is_created
    go_to_clanes
    assert_cache_exists '/gm/clanes/index/newest'
    assert_equal true, @c.update_attributes(:game_ids => [])
    assert_cache_exists '/gm/clanes/index/newest'
  end
  
  def test_should_clear_newest_box_on_portals_when_clan_is_deleted
    test_should_clear_newest_box_on_main_when_new_clan_is_created
    g1 = Game.find(1)
    host! "#{g1.code}.#{App.domain}"
    go_to_clanes
    assert_cache_exists "/#{g1.code}/clanes/index/newest"
    @c.deleted = true
    @c.save
    assert_cache_dont_exist "/#{g1.code}/clanes/index/newest"
  end
  
  def test_should_clear_newest_box_on_portals_when_clan_changes_its_games_associations
    test_should_clear_newest_box_on_main_when_new_clan_is_created
    g1 = Game.find(1)
    host! "#{g1.code}.#{App.domain}"
    go_to_clanes
    assert_cache_exists "/#{g1.code}/clanes/index/newest"
    
    g2 = Game.new(:name => 'rikitauunn', :code => 'ri')
    assert_count_increases(Portal) do
      assert_equal true, g2.save
    end
    host! "#{g2.code}.#{App.domain}"
    
    go_to_clanes
    assert_cache_exists "/#{g2.code}/clanes/index/newest"
    
    assert_equal true, @c.update_attributes(:game_ids => [])
    @c.reload
    assert_cache_dont_exist "/#{g1.code}/clanes/index/newest"
    assert_cache_exists "/#{g2.code}/clanes/index/newest"
    host! "#{g2.code}.#{App.domain}"
    go_to_clanes
    host! "#{g1.code}.#{App.domain}"
    go_to_clanes
    
    assert_equal true, @c.update_attributes(:game_ids => [g2.id])
    @c.reload
    assert_cache_dont_exist "/#{g2.code}/clanes/index/newest"
    assert_cache_exists "/#{g1.code}/clanes/index/newest"
    host! "#{g2.code}.#{App.domain}"
    go_to_clanes
    host! "#{g1.code}.#{App.domain}"
    go_to_clanes
    
    assert_equal true, @c.update_attributes(:game_ids => [1])
    @c.reload
    assert_cache_dont_exist "/#{g2.code}/clanes/index/newest"
    assert_cache_dont_exist "/#{g1.code}/clanes/index/newest"
  end
  
  def test_should_not_clear_biggest_box_on_main_when_clan_changes_its_games_associations
    test_should_clear_newest_box_on_main_when_new_clan_is_created
    go_to_clanes
    assert_cache_exists '/gm/clanes/index/biggest'
    assert_equal true, @c.update_attributes(:game_ids => [])
    assert_cache_exists '/gm/clanes/index/biggest'
  end
  
  def test_should_clear_biggest_box_on_portals_when_clan_changes_its_games_associations
    test_should_clear_newest_box_on_main_when_new_clan_is_created
    g1 = Game.find(1)
    g2 = Game.create(:name => 'rikitauunn', :code => 'ru')
    
    host! "#{g1.code}.#{App.domain}"
    go_to_clanes
    
    host! "#{g2.code}.#{App.domain}"
    go_to_clanes
    
    assert_cache_exists "/#{g1.code}/clanes/index/biggest"
    assert_cache_exists "/#{g2.code}/clanes/index/biggest"
    assert_equal true, @c.update_attributes(:game_ids => [])
    assert_cache_dont_exist "/#{g1.code}/clanes/index/biggest"
    assert_cache_exists "/#{g2.code}/clanes/index/biggest"
  end
  
  def test_should_clear_biggest_box_on_main_when_clan_changes_its_members_count
    test_should_clear_newest_box_on_main_when_new_clan_is_created
    go_to_clanes
    assert_cache_exists '/gm/clanes/index/biggest'
    @c.add_user_to_group(User.find(1), 'clanleaders')
    assert_cache_dont_exist '/gm/clanes/index/biggest'
  end
  
  def test_should_clear_biggest_box_on_portals_when_clan_changes_its_members_count
    test_should_clear_newest_box_on_main_when_new_clan_is_created
    g1 = Game.find(1)
    
    host! "#{g1.code}.#{App.domain}"
    go_to_clanes
    
    assert_cache_exists "/#{g1.code}/clanes/index/biggest"
    @c.add_user_to_group(User.find(1), 'clanleaders')
    assert_cache_dont_exist "/#{g1.code}/clanes/index/biggest"
  end
  
  def test_should_clear_biggest_box_on_main_when_clan_is_deleted
    test_should_clear_newest_box_on_main_when_new_clan_is_created
    go_to_clanes
    assert_cache_exists '/gm/clanes/index/biggest'
    @c.deleted = true
    @c.save
    assert_cache_dont_exist '/gm/clanes/index/biggest'
  end
  
  def test_should_clear_biggest_box_on_portals_when_clan_is_deleted
    test_should_clear_newest_box_on_main_when_new_clan_is_created
    g1 = Game.find(1)
    
    host! "#{g1.code}.#{App.domain}"
    go_to_clanes
    
    assert_cache_exists "/#{g1.code}/clanes/index/biggest"
    @c.deleted = true
    @c.save
    assert_cache_dont_exist "/#{g1.code}/clanes/index/biggest"
  end
  
  def test_should_clear_cache_miembros
    go_to "/clanes/clan/1", 'clanes/clan'
    assert_cache_exists "/common/clanes/1/miembros"
    c1 = Clan.find(1)
    c1.add_user_to_group(User.find(2), 'members')
    assert_cache_dont_exist "/common/clanes/1/miembros"
  end
  
  
  def teardown
    ActionController::Base.perform_caching             = false
  end
end
