# -*- encoding : utf-8 -*-
require 'test_helper'

class CompetitionsMatchTest < ActiveSupport::TestCase

  test "should_complete_match_with_simple_scoring" do
    #    @l = Ladder.find(:first, :conditions => 'invitational is false and competitions_participants_type_id = 1
  end

  test "should_save_with_empty_servers" do
    cm = CompetitionsMatch.find(:first)
    assert_equal true, cm.save
    cm.servers = ''
    assert_equal true, cm.save
  end

  test "should_save_with_correct_servers" do
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

  test "should_save_with_correct_servers_but_duplicated" do
    cm = CompetitionsMatch.find(:first)
    cm.servers = '212.0.107.82 212.0.107.82'
    assert_equal true, cm.save
    assert_equal '212.0.107.82', cm.servers
  end

  test "should_not_save_with_invalid_servers_string" do
    cm = CompetitionsMatch.find(:first)
    cm.servers = ' fuck OYU 127.0.0.1AOMSDOAMDOm 212.107.82'
    assert_equal false, cm.save
  end

  test "should_not_allow_to_set_play_on_to_previous_time" do
    cm = CompetitionsMatch.new({:competition_id => 1, :play_on => 1.second.ago, :event_id => 5000})
    assert_equal false, cm.save
  end

  test "should_send_notification_after_rechallenge" do
    assert_count_increases(ActionMailer::Base.deliveries) do
      cm = CompetitionsMatch.find(:first)
      cm.participant1_id = CompetitionsParticipant.find(:first, :order => 'id ASC').id
      cm.participant2_id = CompetitionsParticipant.find(:first, :order => 'id DESC').id
      assert_equal false, cm.participant1_id == cm.participant2_id
      cm.rechallenge({:play_on => 3.days.since, :servers => ''})
    end
  end


  test "should_allow_supervisor_to_set_result" do
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

  test "shouldnt_play_against_himself" do
    cm = CompetitionsMatch.find(:first)
    cm.participant1_id = 1
    cm.participant2_id = 1
    assert_equal false, cm.save
  end

  test "should_properly_update_related_content_after_changing_participant" do
      cm = CompetitionsMatch.find(:first)
      e = cm.event
      uq = cm.event
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
