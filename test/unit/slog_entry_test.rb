require 'test_helper'

class SlogEntryTest < ActiveSupport::TestCase

  test "decode_editor_scope" do
    assert_equal [50, 1], SlogEntry.decode_editor_scope(50001)
  end

  test "encode_editor_scope" do
    assert_equal 50001, SlogEntry.encode_editor_scope(50, 1)
  end

  test "faction bigboss for boss should work" do
    u2 = User.find(2)
    f1 = Faction.first
    f1.update_boss(u2)
    assert_equal [f1], SlogEntry.scopes(:faction_bigboss, u2)
  end

  test "faction bigboss for underboss should work" do
    u2 = User.find(2)
    f1 = Faction.first
    f1.update_underboss(u2)
    assert_equal [f1], SlogEntry.scopes(:faction_bigboss, u2)
  end

  test "competition supervisor scope must inherit competition_admin scope" do
    u2 = User.find(2)
    c = Ladder.find(:first, :conditions => ['state > ?', Competition::STARTED])
    assert c
    u2.users_roles.create(:role => 'CompetitionAdmin', :role_data => "#{c.id}")
    assert_equal c.id, SlogEntry.scopes(:competition_admin, u2)[0].id
    assert_equal c.id, SlogEntry.scopes(:competition_supervisor, u2)[0].id
  end
end
