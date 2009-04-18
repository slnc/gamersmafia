require 'test_helper'

class LadderTest < ActiveSupport::TestCase
  
  test "shouldnt_have_options" do
    l = Ladder.find(:first)
    assert_equal false, l.has_options?
  end
  
  # TODO more tests
  test "should_be_able_to_challenge_other_participant_user" do
    @ladder = Ladder.find(:first, :conditions => "invitational is false and fee is null and scoring_mode = #{Competition::SCORING_SIMPLE} and state = 3 and competitions_participants_type_id = #{Competition::USERS}")
    u1 = User.find(3)
    u2 = User.find(2)
    @p1 = @ladder.join(u1)
    assert_not_nil @p1
    @p2 = @ladder.join(u2)
    assert_not_nil @p2
    cm_total = CompetitionsMatch.count
    @cm = @ladder.challenge(@p1, @p2)
    assert_not_nil @cm
    assert_equal cm_total + 1, CompetitionsMatch.count
  end
  
  test "should_be_able_to_challenge_other_participant_clan" do
    @ladder = Ladder.find(:first, :conditions => "invitational is false and fee is null and state = 3 and competitions_participants_type_id = #{Competition::CLANS}")
    @u1 = User.find(1)
    @u2 = User.find(2)
    @u1.last_clan_id = 1
    @u2.last_clan_id = 2
    c1 = Clan.find(1)
    c2 = Clan.find(2)
    c2.admins<< @u2
    @p1 = @ladder.join(@u1)
    assert_not_nil @p1
    @p2 = @ladder.join(@u2)
    assert_not_nil @p2
    cm_total = CompetitionsMatch.count
    assert_not_nil @ladder.challenge(@p1, @p2)
    assert_equal cm_total + 1, CompetitionsMatch.count
  end
  
  
  test "should_not_be_able_to_challenge_other_participant_if_unapproved_match_with_him" do
    test_should_be_able_to_challenge_other_participant_user
    cm_total = CompetitionsMatch.count
    assert_raises(RuntimeError) { @ladder.challenge(@p1, @p2) }
    assert_equal cm_total, CompetitionsMatch.count
  end
  
  test "should_not_be_able_to_challenge_other_participant_if_result_pending_match_with_him" do
    test_should_be_able_to_challenge_other_participant_user
    @cm.accept_challenge
    cm_total = CompetitionsMatch.count
    assert_raises(RuntimeError) { @ladder.challenge(@p1, @p2) }
    assert_equal cm_total, CompetitionsMatch.count
  end
  
  test "should_be_able_to_challenge_other_participant_user_if_completed_matches" do
    test_should_not_be_able_to_challenge_other_participant_if_result_pending_match_with_him
    @u1 = User.find(1)
    @cm.competition.add_admin(@u1)
    @cm.complete_match(@u1, {:result => 0, :forfeit_participant1 => nil, :forfeit_participant2 => nil})
    cm_total = CompetitionsMatch.count
    assert_not_nil @ladder.challenge(@p1, @p2)
    assert_equal cm_total + 1, CompetitionsMatch.count
  end
  
  test "should_be_able_to_confirm_result_by_both_participants" do
    test_should_be_able_to_challenge_other_participant_user
    @cm.accept_challenge
    params = {:participation => 'both', :result => 0}
    @cm.complete_match(@p1.the_real_thing, params)
    @cm.reload
    @cm.complete_match(@p2.the_real_thing, params)
    @cm.reload
    assert_equal true, @cm.completed?
  end
  
  test "should_send_notification_to_challenged_participant_after_challenge_sent" do
    
  end
end
