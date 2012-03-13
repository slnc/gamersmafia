require 'test_helper'

class CompetitionsTest < ActiveSupport::TestCase
  test "recalculate_points_should_properly_account_for_double_forfeit_games" do
    lad = Ladder.find(:first, :conditions => "state = 3 and invitational is false and fee is null and competitions_participants_type_id = #{Competition::USERS} and scoring_mode = #{Competition::SCORING_SIMPLE}")
    u1 = User.find(1)
    lad.add_admin(u1)
    assert_not_nil lad
    cp1 = lad.join(u1)
    cp2 = lad.join(User.find(2))
    assert_not_nil cp1
    assert_not_nil cp2
    cm = lad.challenge(cp1, cp2)
    cm.accept_challenge
    assert_not_nil cm
    prev_points_p1 = cp1.points
    prev_points_p2 = cp2.points
    assert_equal true, cm.complete_match(u1, { :participation => 'none', :result => '1'} )
    cp1.reload
    cp2.reload
    assert_equal 1, cp1.losses
    assert_equal 1, cp2.losses
    assert_equal true, cp1.points < 1000
    assert_equal true, cp2.points < 1000
  end
end
