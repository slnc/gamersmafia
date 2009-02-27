require File.dirname(__FILE__) + '/../test_helper'

class FactionTest < Test::Unit::TestCase  
  def setup
    
  end
  
  def test_find_by_bigboss
    f1 = Faction.find(1)
    u1 = User.find(1)
    f1.update_boss(u1)
    assert_equal 1, Faction.find_by_bigboss(u1).id
    f1.update_boss(nil)
    f1.update_underboss(u1)
    assert_equal 1, Faction.find_by_bigboss(u1).id
  end
  
  def test_faction_editors
    f1 = Faction.find(1)
    assert_equal [], f1.editors
  end
  
  def test_create_should_create_slog_entry
    assert_count_increases(SlogEntry) do 
      f = Faction.new({:code => 'oo', :name => "Oinoiroko"})
      assert f.save, f.errors.full_messages_html
    end
  end
  
  def test_update_boss_shouldnt_touch_faction_last_changed_on_if_already_member
    f1 = Faction.find(1)
    f1.members.clear
    u2 = User.find(2)
    Factions.user_joins_faction(u2, f1.id)
    assert u2.update_attributes(:faction_last_changed_on => 1.year.ago)
    f1.update_boss(u2)
    u2.reload
    assert u2.faction_last_changed_on < 1.day.ago
  end
  
  def test_golpe_de_estado_should_work
    f1 = Faction.find(1)
    f1.members.clear
    assert f1.update_boss(User.find(1))
    f1.update_underboss(nil)
    Factions.user_joins_faction(User.find(2), f1.id)
    
    tc = TopicsCategory.find_by_code(f1.code)
    assert_not_nil tc
    assert_count_increases(TopicsCategory) { tc.children.create(:code => 'general', :name => 'General') }
    m = Message.count
    
    assert_count_increases(Topic) do
      f1.golpe_de_estado
    end
    assert_equal m + 3, Message.count # un mensaje al boss y otro al miembro
    
    f1.reload
    assert_nil f1.boss
  end
  
  def test_user_is_editor_if_editor
    f1 = Faction.find(1)
    ctype = ContentType.find(:first)
    u59 = User.find(59)
    assert !f1.user_is_editor_of_content_type?(u59, ctype)
    f1.add_editor(u59, ctype)
    assert f1.user_is_editor_of_content_type?(u59, ctype)
  end
  
  def test_user_is_editor_if_boss
    f1 = Faction.find(1)
    ctype = ContentType.find(:first)
    assert !f1.user_is_editor_of_content_type?(User.find(59), ctype)
    assert f1.update_boss(User.find(59))
    assert f1.user_is_editor_of_content_type?(User.find(59), ctype)
  end
  
  def test_user_is_editor_if_underboss
    f1 = Faction.find(1)
    ctype = ContentType.find(:first)
    u59 = User.find(59)
    assert !f1.user_is_editor_of_content_type?(u59, ctype)
    assert f1.update_boss(u59)
    assert f1.user_is_editor_of_content_type?(u59, ctype)
  end
  
  def test_proper_boss
    f1 = Faction.find(1)
    u59 = User.find(59)
    assert f1.update_boss(u59)
    f1.reload
    assert_equal 59, f1.boss.id
  end
  
  def test_karma_points_should_work_correctly
    flunk
  end
end
