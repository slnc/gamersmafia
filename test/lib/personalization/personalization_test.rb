require File.dirname(__FILE__) + '/../../../test/test_helper'

class PersonalizationTest < ActiveSupport::TestCase
  # TODO estos tests fallan y no se por que, parece que no se borre la bd despues de ejecutarlos
  test "quicklinks_empty" do
    u2 = User.find(2)
    qlinks = Personalization.quicklinks_for_user(u2)
    assert_equal 0, qlinks.size
  end
  
  test "quicklinks_faction_id" do
    u2 = User.find(2)
    u2.preferences.clear # los otros tests afectan a este, no entiendo por que
    Factions.user_joins_faction(u2, Faction.find(:first))
    qlinks = Personalization.quicklinks_for_user(u2)
    assert_equal 1, qlinks.size
  end
  
  test "quicklinks_add" do
    @u2 = User.find(2)
    
    Personalization.add_quicklink(@u2, 'deportes', 'http://deportes.gamersmafia.com/')
    qlinks = Personalization.quicklinks_for_user(@u2)
    
    assert_equal 1, qlinks.size
    assert_equal 'deportes', qlinks[0][:code]
  end
  
  test "quicklinks_del" do
    test_quicklinks_add
    Personalization.del_quicklink(@u2, 'deportes')
    qlinks = Personalization.quicklinks_for_user(@u2)
    assert_equal 0, qlinks.size
  end
  
  test "user_forums_add" do
    @u2 = User.find(2)
    @tcf = Term.single_toplevel(:slug => 'ut').children.find(:first, :conditions => 'name = \'General\' AND taxonomy = \'TopicsCategory\'')
    Personalization.add_user_forum(@u2, @tcf.id, ApplicationController.gmurl(@tcf))
    ufs = Personalization.get_user_forums(@u2)
    
    assert_equal 3, ufs.size
    assert_equal 1, ufs[0].size
    assert_equal @tcf.id, ufs[0][0]
  end
  
  test "user_forums_del" do
    test_user_forums_add
    Personalization.del_user_forum(@u2, @tcf.id)
    ufs = Personalization.get_user_forums(@u2)
    assert_equal 0, ufs[0].size
  end
end
