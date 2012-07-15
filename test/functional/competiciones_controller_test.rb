# -*- encoding : utf-8 -*-
require 'test_helper'

class CompeticionesControllerTest < ActionController::TestCase

  test "should_not_be_able_to_join_if_state_not_1" do
    [0, 2, 3, 4].each do |state|
      c = Competition.find(:first, :conditions => ['invitational is false and fee is null and competitions_participants_type_id = 1 and state = ? and type <> \'Ladder\'', state])
      u = User.find(2)
      c.competitions_participants.clear
      assert_not_nil c
      assert_raises(ActiveRecord::RecordNotFound) { get :join_competition, {:id => c.id}, {:user => 2} }
      assert_nil c.get_active_participant_for_user(u)
    end
  end

  test "should_be_able_to_join_if_state_1_and_not_ladder" do
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and state = 1 and type <> \'Ladder\'')
    assert_not_nil c
    sym_login 2
    get :join_competition, {:id => c.id}
    assert_response :redirect
    u = User.find(2)
    assert_not_nil c.get_active_participant_for_user(u)
  end

  test "should_be_able_to_join_if_state_3_and_ladder" do
    self.join_open_ladder
    u = User.find(2)
    assert_not_nil @c.get_active_participant_for_user(u)
  end

  def join_open_ladder
    @c = Ladder.for_individuals.non_invitational.free_admission.find(
        :first, :conditions => 'state = 3')
    assert_not_nil @c
    sym_login 2
    get :join_competition, {:id => @c.id}
    assert_response :redirect
  end

  test "should_set_active_competition_to_last_competition_used_when_joining_and_is_user" do
    u2 = User.find(2)
    last_competition_id = u2.last_competition_id
    test_should_be_able_to_join_if_state_3_and_ladder
    u2.reload
    assert u2.last_competition_id != last_competition_id
  end

  test "should_set_active_competition_to_last_competition_used_when_joining_and_is_clan" do
    u = User.find(1)
    u.last_clan_id = 1
    u.save
    clan = Clan.find(1)
    c = Ladder.free_admission.non_invitational.for_clans.find(
        :first, :conditions => "state = 3")
    u.games<< c.game
    assert_not_nil c

    sym_login 1
    get :join_competition, {:id => c.id}
    assert_response :redirect
    assert_not_nil c.get_active_participant_for_user(u)
    last_competition_id = u.last_competition_id
    u.reload
    assert_equal 1, u.last_clan_id
    assert_equal c.id, u.last_competition_id

  end

  test "should_be_able_to_leave_if_ladder_or_inscriptions_open" do
    u = User.find(1)
    u.last_clan_id = 1
    u.save
    clan = Clan.find(1)

    u.add_money(1000)
    clan.add_money(1000)

    orig_cash = {'User' => u.cash, 'Clan' => clan.cash}
    for c in Competition.find(:all, :conditions => 'state = 1')
      p_type = c.competitions_participants_type == 1 ? 'User' : 'Clan'

      if c.invitational?
        if c.competitions_participants_type == 1
          c.allowed_competitions_participants.create(:participant_id => u.id)
        else
          c.allowed_competitions_participants.create(:participant_id => clan.id)
        end
      end

      sym_login 1
      get :join_competition, {:id => c.id}
      assert_response :redirect
      p = c.get_active_participant_for_user(u)
      assert c.competitions_participants.find(p.id)

      sym_login 1
      get :leave, {:id => c.id}
      assert_response :redirect
      if c.fee?
        assert_equal(orig_cash[p_type], p.the_real_thing.cash,
                     "#{orig_cash[p_type]} vs #{p.the_real_thing.cash}")
      end
      assert_raises(ActiveRecord::RecordNotFound) do
        c.competitions_participants.find(p.id)
      end
    end
  end

  test "index" do
    get :index
    assert_response :success
  end

  test "mapa" do
    get :mapa, :id => GamesMap.find(:first).id
    assert_response :success
  end

  test "should_not_allow_to_show_competition_in_state_0" do
    c = Competition.find(:first, :conditions => 'state = 0')
    assert_not_nil c
    assert_raises(ActiveRecord::RecordNotFound) { get :show, :id => c.id }
  end

  test "should_allow_to_see_index_of_competitions_when_not_in_state_0" do
    # lo hacemos con todas porque show tiene mucha funcionalidad
    # TODO no es completamente exhaustivo
    for c in Competition.find(:all, :conditions => 'state <> 0 and scoring_mode = 0') # el scoring_mode = 0 pq son innecesarios
      get :show, :id => c.id
      assert_response :success
    end
  end

  test "should_not_allow_to_see_reglas_of_competitions_when_in_state_0" do
    c = Competition.find(:first, :conditions => 'state = 0')
    assert_not_nil c
    assert_raises(ActiveRecord::RecordNotFound) { get :reglas, :id => c.id }
  end

  test "should_allow_to_see_reglas_of_competitions_when_not_in_state_0" do
    c = Competition.find(:first, :conditions => 'state > 0')
    assert_not_nil c
    get :reglas, :id => c.id
    assert_response :success
  end

  test "should_not_allow_to_see_participantes_of_competitions_when_in_state_0" do
    c = Competition.find(:first, :conditions => 'state = 0')
    assert_not_nil c
    assert_raises(ActiveRecord::RecordNotFound) { get :reglas, :id => c.id }
  end

  test "should_allow_to_see_participantes_of_competitions_when_not_in_state_0" do
    c = Competition.find(:first, :conditions => 'state > 0')
    assert_not_nil c
    get :participantes, :id => c.id
    assert_response :success
  end

  test "should_not_allow_to_see_ranking_when_in_a_tournament" do
    c = Tournament.find(:first, :conditions => 'state > 3')
    assert_not_nil c
    assert_raises(ActiveRecord::RecordNotFound) { get :ranking, :id => c.id }
  end

  test "should_not_allow_to_see_ranking_when_in_a_ladder_not_started" do
    c = Ladder.find(:first, :conditions => 'state < 3')
    assert_not_nil c
    assert_raises(ActiveRecord::RecordNotFound) { get :ranking, :id => c.id }
  end

  test "should_not_allow_to_see_ranking_when_in_a_league_not_started" do
    c = League.find(:first, :conditions => 'state < 3')
    assert_not_nil c
    assert_raises(ActiveRecord::RecordNotFound) { get :ranking, :id => c.id }
  end

  test "should_allow_to_see_ranking_when_in_a_league" do
    c = League.find(:first, :conditions => 'state >= 3')
    assert_not_nil c
    get :ranking, :id => c.id
    assert_response :success
  end

  test "should_allow_to_see_ranking_when_in_a_ladder" do
    c = Ladder.find(:first, :conditions => 'state >= 3')
    assert_not_nil c
    get :ranking, :id => c.id
    assert_response :success
  end

  test "should_allow_to_see_partidas_when_in_a_ladder" do
    c = Ladder.find(:first, :conditions => 'state >= 3')
    assert_not_nil c
    get :partidas, :id => c.id
    assert_response :success
  end

  test "should_show_challenge_page_when_challenging_participant" do
    self.join_open_ladder

    sym_login 3
    get :join_competition, {:id => @c.id}
    assert_response :redirect
    @u3 = User.find(3)
    assert_not_nil @c.get_active_participant_for_user(@u3)

    sym_login 2
    get :retar, { :id => @c.get_active_participant_for_user(@u3).id }
  end

  test "should_be_able_to_challenge_user" do
    test_should_show_challenge_page_when_challenging_participant
    cm_count = @c.competitions_matches.count
    post :do_retar, {
        :id => @c.get_active_participant_for_user(@u3).id,
        :competitions_match => {:play_on => '', :servers =>  ''}
    }
    assert_response :redirect
    assert_equal cm_count + 1, @c.competitions_matches.count
  end

  test "responder_reto" do
    test_should_be_able_to_challenge_user
    sym_login @u3.id
    get :responder_reto, {
        :id => @c.competitions_matches.find(:first, :order => 'id desc').id
    }
    assert_response :success
  end


  test "cancelar_reto" do
    test_should_be_able_to_challenge_user
    cm = @c.competitions_matches.find(:first, :order => 'id desc')
    post :cancelar_reto, {
        :participant1_id => cm.participant1_id,
        :participant2_id => cm.participant2_id
    }
    assert_response :redirect
    assert_nil CompetitionsMatch.find_by_id(cm.id)
  end

  test "do_accept_challenge" do
    test_should_be_able_to_challenge_user
    cm = @c.competitions_matches.find(:first, :order => 'id desc')
    sym_login @u3.id
    post :do_accept_challenge, :competitions_match_id => cm.id
    assert_response :redirect
    cm.reload
    assert cm.accepted
  end

  test "do_deny_challenge" do
    test_should_be_able_to_challenge_user
    sym_login @u3.id
    cm = @c.competitions_matches.find(:first, :order => 'id desc')
    post :do_deny_challenge, :competitions_match_id => cm.id
    assert_response :redirect
    assert_nil CompetitionsMatch.find_by_id(cm.id)
  end

  test "borrar_upload" do
    sym_login 1
    prepare_for_competitions_match_tests
    assert_count_decreases(CompetitionsMatchesUpload) do
      post :borrar_upload, :id => CompetitionsMatchesUpload.find(:first).id
    end
  end

  def prepare_for_competitions_match_tests
    @cm = CompetitionsMatch.find(:first)
    @cm.participant1_id = 1
    @cm.participant2_id = 2
    assert @cm.save
    @cm.competition.add_admin(User.find(1))
    sym_login 1
  end

  test "nuevo_informe" do
    prepare_for_competitions_match_tests
    get :nuevo_informe, {:id => @cm.id }
    assert_response :success
  end

  test "create_report" do
    test_nuevo_informe
    assert_count_increases(CompetitionsMatchesReport) do
      post :create_report, {
          :id => 1, :competitions_matches_report => {:report => 'po fale'}
      }
    end
    assert_response :redirect
  end

  test "editar_informe" do
    test_create_report
    get :editar_informe, {
        :id => CompetitionsMatchesReport.find(:first, :order => 'id desc').id
    }
    assert_response :success
  end

  test "update_report" do
    test_create_report
    cmr = CompetitionsMatchesReport.find(:first, :order => 'id desc')
    post :update_report, {
        :id => cmr.id,
        :competitions_matches_report => { :report => 'yolei'}
    }
    cmr.reload
    assert_equal 'yolei', cmr.report
    assert_response :redirect
  end

  test "informe" do
    cmr = CompetitionsMatchesReport.find(:first)
    get :informe, :id => cmr.id
    assert_response :success
  end

  test "upload_file" do
    prepare_for_competitions_match_tests
    assert_count_increases(CompetitionsMatchesUpload) do
      post :upload_file, {
          :id => 1,
          :competitions_matches_upload => {
              :file => fixture_file_upload('files/buddha.jpg', 'image/jpeg')
          }
      }
    end
  end

  test "partida_shouldnt_work_if_competition_not_started" do
    cm = CompetitionsMatch.find(:first)
    User.db_query("UPDATE competitions set state = 1 where id = #{cm.competition_id}")
    assert_raises(ActiveRecord::RecordNotFound) { get :partida, :id => cm.id }
  end

  test "partida_should_work_if_competition_started" do
    cm = CompetitionsMatch.find(:first)
    User.db_query("UPDATE competitions set state = 3 where id = #{cm.competition_id}")
    get :partida, :id => cm.id
    assert_response :success
  end

  test "participante" do
    get :participante, :id => CompetitionsParticipant.find(:first).id
    assert_response :success
  end
end
