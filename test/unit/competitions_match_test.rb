require File.dirname(__FILE__) + '/../test_helper'

class CompetitionsMatchTest < ActiveSupport::TestCase
  
  # Replace this with your real tests.
  def test_should_complete_match_with_simple_scoring
    #    @l = Ladder.find(:first, :conditions => 'invitational is false and competitions_participants_type_id = 1
  end
  
  def test_should_save_with_empty_servers
    cm = CompetitionsMatch.find(:first)
    assert_equal true, cm.save
    cm.servers = ''
    assert_equal true, cm.save
  end
  
  def test_should_save_with_correct_servers
    cm = CompetitionsMatch.find(:first)
    [' 212.0.107.81', 
     '212.0.107.80, 212.0.107.81 ', 
     '212.0.107.80,212.0.107.81', 
     ' 212.0.107.80 212.0.107.81',
     'www.gamersmafia.com',
     ' 212.0.107.81, www.gamersmafia.com ',
     ' www.jolt.co.uk, www.gamersmafia.com ',].each do |servers|
      cm.servers = servers
      assert_equal true, cm.save
      assert_equal servers.strip.gsub(' ', ',').gsub(',,',','), cm.servers
    end
  end
  
  def test_should_save_with_correct_servers_but_duplicated
    cm = CompetitionsMatch.find(:first)
    cm.servers = '212.0.107.82 212.0.107.82'
    assert_equal true, cm.save
    assert_equal '212.0.107.82', cm.servers
  end
  
  def test_should_not_save_with_invalid_servers_string
    cm = CompetitionsMatch.find(:first)
    cm.servers = ' fuck OYU 127.0.0.1AOMSDOAMDOm 212.107.82'
    assert_equal false, cm.save
  end
  
  def test_should_not_allow_to_set_play_on_to_previous_time
    cm = CompetitionsMatch.new({:competition_id => 1, :play_on => 1.second.ago, :event_id => 5000})
    assert_equal false, cm.save
  end
  
  def test_should_send_notification_after_rechallenge
    assert_count_increases(ActionMailer::Base.deliveries) do 
      cm = CompetitionsMatch.find(:first)
      cm.participant1_id = CompetitionsParticipant.find(:first, :order => 'id ASC').id
      cm.participant2_id = CompetitionsParticipant.find(:first, :order => 'id DESC').id
      assert_equal false, cm.participant1_id == cm.participant2_id
      cm.rechallenge({:play_on => 3.days.since, :servers => ''})
    end
  end
  
  
  def test_should_allow_supervisor_to_set_result
    panzer = User.find(2)
    cm = CompetitionsMatch.find(:first)
    cm.accepted = true
    cm.save
    c = cm.competition
    (c.state = Competition::STARTED ; c.save) unless c.state == Competition::STARTED
#    
#      User.db_query("UPDATE competitions SET state = #{Competition::STARTED} WHERE id = #{c.id}")
#      c = Competition.find(c.id)
#    end
#    assert_equal true, c.is_a?(Ladder)
    c.add_supervisor(panzer)
    assert_equal true, c.user_is_supervisor(panzer)
    assert_equal true, cm.can_set_result?(panzer)
  end
  
  def test_shouldnt_play_against_himself
    cm = CompetitionsMatch.find(:first)
    cm.participant1_id = 1
    cm.participant2_id = 1
    assert_equal false, cm.save
  end
  
  def test_should_properly_update_related_content_after_changing_participant
      cm = CompetitionsMatch.find(:first)
      e = cm.event
      uq = cm.event.unique_content
      prev_e = e.title
      prev_uq = uq.name
      cm.participant2_id = 2
      assert_equal true, cm.save
      e.reload
      uq.reload
      assert_equal false, prev_e == e.title, e.title
      assert_equal false, prev_uq == uq.name, uq.name
  end
end
