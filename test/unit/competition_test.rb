require File.dirname(__FILE__) + '/../test_helper'

class CompetitionTest < ActiveSupport::TestCase

  # TODO test user_indicator
  
  #  def test_update_user_indicator
  #    superadmin = new_session_as(:superadmin)
  #    panzer = new_session_as(:panzer)
  #    assert_equal false, superadmin.enable_competition_indicator
  #    assert_equal false, panzer.enable_competition_indicator
  #
  #    ladder = superadmin.creates_ladder({:name => 'foo', :game_id => 1, :competitions_participants_type_id => 1})
  #    ladder.start
  #    ladder.join(superadmin)
  #    ladder.join(panzer)
  #    superadmin_participant = ladder.get_active_participant_for_user(superadmin)
  #    panzer_participant = ladder.get_active_participant_for_user(panzer)
  #    superadmin_participant.challenge(panzer_participant)
  #    assert_equal false, superadmin.enable_competition_indicator
  #    assert_equal true, panzer.enable_competition_indicator
  #  end
  #
  #  private
  #  module CompetitionTestingDSL
  #    def autologs_in_as(login)
  #      @user = User.find_by_login(login)
  #      key = AutologinKey.find_by_user_id(@user.id)
  #      post '/', :login => login
  #      assert_redirected_to '/cuenta'
  #    end
  #
  #    def new_session_as(person)
  #      new_session do |sess|
  #        sess.goes_to_login
  #        sess.logs_in_as_(person)
  #        yield sess if block_given?
  #      end
  #    end
  #  end
  
  def test_should_send_notifications_to_allowed_participants_if_invitational_and_switching_to_state_1_and_users
    c = Competition.find(:first, :conditions => "state = 0 AND invitational is true and competitions_participants_type_id = #{Competition::USERS}")
    prev = ActionMailer::Base.deliveries.size
    c.allowed_competitions_participants.create({:participant_id => 1})
    assert_equal prev, ActionMailer::Base.deliveries.size
    c.description = 'hola'
    c.save
    c.switch_to_state(1)
    assert_equal prev + 1, ActionMailer::Base.deliveries.size
  end
  
  def test_should_send_notifications_to_allowed_participants_if_invitational_and_switching_to_state_1_and_clans
    c = Competition.find(:first, :conditions => "state = 0 AND invitational is true and competitions_participants_type_id = #{Competition::CLANS}")
    prev = ActionMailer::Base.deliveries.size
    c.allowed_competitions_participants.create({:participant_id => 1})
    clan = Clan.find(1)
    assert_equal prev, ActionMailer::Base.deliveries.size
    c.description = 'hola'
    c.save
    c.switch_to_state(1)
    assert_equal prev + 1, ActionMailer::Base.deliveries.size
  end
  
  def test_should_be_able_to_join_competition_if_user_and_everything_ok
    ladder = Ladder.find(:first, :conditions => "invitational is false and fee is null and state = 3 and competitions_participants_type_id = #{Competition::USERS}")
    u1 = User.find(1)
    p1 = ladder.join(u1)
    assert p1.kind_of?(CompetitionsParticipant)
  end
  
  
  def test_should_set_closed_on_when_closed
    [Tournament.find(:first, :conditions => 'state = 3'), League.find(:first, :conditions => 'state = 3')].each do |c|
      assert_equal true, c.switch_to_state(4)
      assert_not_nil c.closed_on
    end
  end
  
  # TODO resto de tests
end
