require 'test_helper'

class GameTest < ActiveSupport::TestCase
  
  def setup
    @game = Game.find(1)
  end
  
  test "create_term" do
    test_should_create_if_everything_ok
    t = Term.find(:first, :conditions => ['game_id = ? AND parent_id IS NULL', @g.id])
    assert t
    assert_equal @g.name, t.name
    assert_equal @g.code, t.slug
  end
  
  test "should_not_create_if_missing_fields" do
    c = Game.count
    g = Game.new({:name => 'foo'})
    assert_equal false, g.save
    
    g = Game.new({:code => 'foo'})
    assert_equal false, g.save
    
    g = Game.new()
    assert_equal false, g.save
    
    assert_equal c, Game.count
  end
  
  test "should_create_if_everything_ok" do
    @g = Game.new({:name => 'Worms', :code => 'w'})
    assert_equal true, @g.save, @g.errors.to_yaml
    assert_not_nil Game.find_by_name('Worms')
    assert_not_nil Game.find_by_code('w')
  end
  
  test "should_not_create_if_duplicated_name_or_code" do
    test_should_create_if_everything_ok
    g2 = Game.new({:name => 'Worms', :code => 'w'})
    assert_equal false, g2.save
    assert_not_nil g2.errors[:name]
    assert_not_nil g2.errors[:code]
  end
  
  test "should_not_create_if_invalid_chars_in_name_or_code" do
    g = Game.new({:name => 'Battlefield Vietnäm', :code => 'Bf: 2'})
    assert_equal false, g.save
    assert_not_nil g.errors[:code]
    assert_not_nil g.errors[:name]
  end
  
  test "should_create_faction_if_everything_ok" do
    test_should_create_if_everything_ok
    assert_not_nil Faction.find_by_code(@g.code)
    assert_not_nil Faction.find_by_name(@g.name)
  end
  
  test "should_create_contents_categories_if_everything_ok" do
    test_should_create_if_everything_ok
    root_term = Term.single_toplevel(:game_id => @g.id)
    assert_not_nil root_term
    Organizations::DEFAULT_CONTENTS_CATEGORIES.each do |c|
      assert_not_nil root_term.children.find(:first, :conditions => ['taxonomy = ? AND name = ?', c[0], c[1]])  
    end
  end
  
  test "should_create_portal_if_everything_ok" do
    test_should_create_if_everything_ok
    p = Portal.find(:first, :conditions => ['name = ? and code = ?', @g.name, @g.code])
    f = Faction.find(:first, :conditions => ['name = ? and code = ?', @g.name, @g.code])
    assert_not_nil p
    assert_equal 1, p.factions.size
    assert_equal p.factions[0].id, f.id
  end
end
