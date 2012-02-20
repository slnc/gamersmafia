require 'test_helper'

class CompetitionTest < ActiveSupport::TestCase

  # TODO test user_indicator

  #  test "update_user_indicator" do
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

  test "should_send_notifications_to_allowed_participants_if_invitational_and_switching_to_state_1_and_users" do
    c = Competition.find(:first, :conditions => "state = 0 AND invitational is true and competitions_participants_type_id = #{Competition::USERS}")
    prev = ActionMailer::Base.deliveries.size
    c.allowed_competitions_participants.create({:participant_id => 1})
    assert_equal prev, ActionMailer::Base.deliveries.size
    c.description = 'hola'
    c.save
    c.switch_to_state(1)
    assert_equal prev + 1, ActionMailer::Base.deliveries.size
  end

  test "should_send_notifications_to_allowed_participants_if_invitational_and_switching_to_state_1_and_clans" do
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

  test "should_be_able_to_join_competition_if_user_and_everything_ok" do
    ladder = Ladder.find(:first, :conditions => "invitational is false and fee is null and state = 3 and competitions_participants_type_id = #{Competition::USERS}")
    u1 = User.find(1)
    p1 = ladder.join(u1)
    assert p1.kind_of?(CompetitionsParticipant)
  end


  test "should_set_closed_on_when_closed" do
    [Tournament.find(:first, :conditions => 'state = 3'), League.find(:first, :conditions => 'state = 3')].each do |c|
      assert_equal true, c.switch_to_state(4)
      assert_not_nil c.closed_on
    end
  end

  test "should not be able to start competition without players" do
    [Tournament, League].each do |c_class|
      c = c_class.find(:first, :conditions => 'state = 2')
      assert_raises(Exception) do
        c.switch_to_state(Competition::STARTED)
      end
    end
  end

  test "can recreate matches" do
    [Tournament, League].each do |c_class|
      c = c_class.find(:first, :conditions => 'state = 1')
      assert c.can_recreate_matches?, "#{c_class}(Competition) can't recreate matches!!"
    end

    assert League.find(1).can_recreate_matches?
  end

  test "should create group matches correctly in tournament that uses classifiers" do
    c = Tournament.new(:name => 'Hattrick GM-2',
                       :competitions_participants_type_id => Competition::USERS,
                       :rules => 'foooa bo',
                       :description => 'adadada',
                       :competitions_types_options => HashWithIndifferentAccess.new({ :tourney_classifiers_rounds => '2',
                                                        :tourney_classifiers_rounds => '2',
                                                        :tourney_rounds => '4',
                                                        :tourney_groups => '8',
                                                        :tourney_use_classifiers => 'on' }),
                       :game_id => 1,
                       :cash => '0.00',
                       :timetable_for_matches => '0',
                       :send_notifications => 't',
                       :scoring_mode => '0')
    assert c.save
    c.switch_to_state(1)

    # create users
     (1..26).each do |i|
      u = User.new(:login => "gmht2cp#{i}", :password => 'booooo', :email => "em#{i}@gmht2.com", :ipaddr => '0.0.0.0', :lastseen_on => Time.now)
      assert u.save, u.errors.full_messages_html
      u.change_internal_state(:active)
      assert_count_increases(CompetitionsParticipant) do
        c.add_participant(u)
      end
    end
    c.switch_to_state(Competition::INSCRIPTIONS_CLOSED)
    c.switch_to_state(Competition::STARTED)
    # Check group creation is correct
    assert_equal 8, c.tourney_groups
    groups = c.tourney_classifier_groups
    assert_equal 8, groups.size
    u1 = User.find(1)
    c.add_admin(u1)
    matches_clasificatorias = 0
    groups.each do |g|
      group_participants_ids = g.participants.collect { |cp| cp.id }
      matches_remaining = group_participants_ids.each_choose(2)

      g.matches.each do |cm|
        matches_clasificatorias += 1
        matches_remaining.delete_if { |cmids| (cm.participant1_id == cmids[0] && cm.participant2_id == cmids[1]) || (cm.participant1_id == cmids[1] && cm.participant2_id == cmids[0])}
        cm.complete_match(u1, :participation => 'both', :result => 0)
      end
      assert_equal 0, matches_remaining.size
    end

    # Check matches in eliminatorias
    total_eliminatorias = 15
    assert_equal 8, c.matches(:octavos, :count => true)
    assert_equal 4, c.matches(:cuartos, :count => true)
    assert_equal 2, c.matches(:semifinales, :count => true)
    assert_equal 1, c.matches(:final, :count => true)

    # TODO check that the participants are actually correct

    # now make sure that eliminatorias works
    c.competitions_matches.find(:all, :conditions => ['stage = ?', c.tourney_rounds_starting_stage], :order => "id ASC").each do |cm|
      #p cm
      assert_not_nil cm.participant1_id
      assert_not_nil cm.participant2_id
      cm.complete_match(u1, :participation => 'both', :result => 0)
    end

    c.competitions_matches.find(:all, :conditions => ['stage = ?', c.tourney_rounds_starting_stage + 1], :order => "id ASC").each do |cm|
      #p cm
      assert_not_nil cm.participant1_id
      assert_not_nil cm.participant2_id
      cm.complete_match(u1, :participation => 'both', :result => 0)
    end

    c.competitions_matches.find(:all, :conditions => ['stage = ?', c.tourney_rounds_starting_stage + 2], :order => "id ASC").each do |cm|
      #p cm
      assert_not_nil cm.participant1_id
      assert_not_nil cm.participant2_id
      cm.complete_match(u1, :participation => 'both', :result => 0)
    end

    c.competitions_matches.find(:all, :conditions => ['stage = ?', c.tourney_rounds_starting_stage + 3], :order => "id ASC").each do |cm|
      #p cm
      assert_not_nil cm.participant1_id
      assert_not_nil cm.participant2_id
      cm.complete_match(u1, :participation => 'both', :result => 0)
    end
  end

  test "tourney groups should properly compute" do
    t = Tournament.first
    # We want to start in octavos and have 3 winners per group
    t.competitions_types_options = HashWithIndifferentAccess.new({:tourney_rounds => 4, :tourney_classifiers_rounds => 3})
    assert_equal 6, t.tourney_groups
  end

  # TODO resto de tests
end
