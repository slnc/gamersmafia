require File.dirname(__FILE__) + '/../test_helper'

class AllowedCompetitionsParticipantTest < Test::Unit::TestCase
  
  def test_should_send_notification_after_being_invited_if_competition_is_invitational_and_in_state_gt_0_and_users
    u = User.find(1)
    c = Competition.find(:first, :conditions => "invitational is true and fee is null and state BETWEEN 1 AND 3 and competitions_participants_type_id = #{Competition::USERS}")
    assert_not_nil c
    prev = ActionMailer::Base.deliveries.size
    c.allowed_competitions_participants.create({:participant_id => u.id})
    assert_equal prev + 1, ActionMailer::Base.deliveries.size
  end
  
  def test_should_send_notification_after_being_invited_if_competition_is_invitational_and_in_state_gt_0_and_clans
    u = User.find(1)
    c = Competition.find(:first, :conditions => "invitational is true and fee is null and state BETWEEN 1 AND 3 and competitions_participants_type_id = #{Competition::CLANS}")
    clan = Clan.find(1)
    clan.add_user_to_group(u, 'clanleaders') unless clan.user_is_clanleader(u.id)
    assert_not_nil c
    prev = ActionMailer::Base.deliveries.size
    c.allowed_competitions_participants.create({:participant_id => clan.id})
    assert_equal prev + 1, ActionMailer::Base.deliveries.size
  end
  
  def test_should_not_send_notification_after_being_invited_if_competition_is_invitational_but_in_state_0
    u = User.find(1)
    c = Competition.find(:first, :conditions => "invitational is true and fee is null and state = 0 and competitions_participants_type_id = #{Competition::USERS}")
    assert_not_nil c
    prev = ActionMailer::Base.deliveries.size
    c.allowed_competitions_participants.create({:participant_id => u.id})
    assert_equal prev, ActionMailer::Base.deliveries.size    
  end
end
