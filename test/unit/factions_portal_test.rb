require File.dirname(__FILE__) + '/../test_helper'

class FactionsPortalTest < Test::Unit::TestCase
  
  def test_should_return_factions_links_if_any
    @fp = FactionsPortal.create({:name => 'fooo', :code => 'fooo'})
    assert_equal false, @fp.new_record?
    f = Faction.create({:name => 'fooo', :code => 'fooo'})
    assert_equal false, f.new_record?
    flc = f.factions_links.create({:name => 'nombre del link', :url => 'http://google.com/', :image => fixture_file_upload('/files/babe.jpg', 'image/jpeg')})
    assert_equal false, flc.new_record?
    @fp.factions<< f
    assert_equal 1, @fp.factions_links.size
    assert_equal flc.id, @fp.factions_links[0].id
  end
  
  def test_should_not_return_duplicated_urls
    test_should_return_factions_links_if_any
    @fp.reload
    f2 = Faction.create({:name => 'fooo2', :code => 'fooo2'})
    assert_equal false, f2.new_record?
    flc2 = f2.factions_links.create({:name => 'nombre del link2', :url => 'http://google.com/', :image => fixture_file_upload('/files/babe.jpg', 'image/jpeg')})
    assert_equal false, flc2.new_record?
    @fp.factions<< f2
    
    assert_equal 1, @fp.factions_links.size
    assert_equal flc2.url, @fp.factions_links[0].url
  end
  
  def test_contents_type_categories_should_return_proper_categories_if_faction_of_game
    assert_equal 1, Portal.find_by_code('ut').tutorials_categories.size
  end
  
  def test_contents_type_categories_should_return_proper_categories_if_faction_of_platform
    assert_equal 1, Portal.find_by_code('wii').tutorials_categories.size
  end
  
  def test_categories_should_work
    portal_ut = Portal.find_by_code('ut')
    assert_equal 1, portal_ut.categories(Tutorial).size
    assert_equal 'ut', portal_ut.categories(Tutorial)[0].slug
    assert_equal Faction.find_by_code('ut').id, portal_ut.categories(Tutorial)[0].game_id
  end
  
  def test_get_categories_should_work
    portal_ut = Portal.find_by_code('ut')
    cats = portal_ut.get_categories(Tutorial)
    assert_equal 2, cats.size
    assert_equal 1, cats[1]
  end
end
