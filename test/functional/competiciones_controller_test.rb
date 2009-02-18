require File.dirname(__FILE__) + '/../test_helper'
require 'competiciones_controller'

# Re-raise errors caught by the controller.
class CompeticionesController; def rescue_action(e) raise e end; end

class CompeticionesControllerTest < Test::Unit::TestCase
  def setup
    @controller = CompeticionesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_should_not_be_able_to_join_if_state_not_1
    [0, 2, 3, 4].each do |state|
      c = Competition.find(:first, :conditions => ['invitational is false and fee is null and competitions_participants_type_id = 1 and state = ? and type <> \'Ladder\'', state])
      assert_not_nil c
      assert_raises(ActiveRecord::RecordNotFound) { get :join_competition, {:id => c.id}, {:user => 2} }
      u = User.find(2)
      assert_nil c.get_active_participant_for_user(u)
    end
  end
  
  def test_should_be_able_to_join_if_state_1_and_not_ladder
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and state = 1 and type <> \'Ladder\'')
    assert_not_nil c
    get :join_competition, {:id => c.id}, {:user => 2}
    assert_response :redirect
    u = User.find(2)
    assert_not_nil c.get_active_participant_for_user(u)
  end
  
  def test_should_be_able_to_join_if_state_3_and_ladder
    @c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and state = 3 and type = \'Ladder\'')
    assert_not_nil @c
    get :join_competition, {:id => @c.id}, {:user => 2}
    assert_response :redirect
    u = User.find(2)
    assert_not_nil @c.get_active_participant_for_user(u)
  end
  
  def test_should_set_active_competition_to_last_competition_used_when_joining_and_is_user
    u2 = User.find(2)
    last_competition_id = u2.last_competition_id
    test_should_be_able_to_join_if_state_3_and_ladder
    u2.reload
    assert u2.last_competition_id != last_competition_id
  end
  
  def test_should_set_active_competition_to_last_competition_used_when_joining_and_is_clan
    u = User.find(1)
    u.last_clan_id = 1
    u.save
    clan = Clan.find(1)
    #    clan.add_user_to_group(u, 'clanleaders')
    c = Competition.find(:first, :conditions => "invitational is false and fee is null and competitions_participants_type_id = #{Competition::CLANS} and state = 3 and type = 'Ladder'")
    u.games<< c.game
    assert_not_nil c
    get :join_competition, {:id => c.id}, {:user => 1}
    assert_response :redirect
    assert_not_nil c.get_active_participant_for_user(u)
    last_competition_id = u.last_competition_id
    u.reload
    assert_equal 1, u.last_clan_id
    assert_equal c.id, u.last_competition_id
    
  end
  
  def test_should_be_able_to_leave_if_ladder_or_inscriptions_open
    u = User.find(1)
    u.last_clan_id = 1
    u.save
    clan = Clan.find(1)
    #    clan.add_user_to_group(u, 'clanleaders')
    
    u.add_money(1000)
    clan.add_money(1000)
    
    orig_cash = {'User' => u.cash, 'Clan' => clan.cash}
    for c in Competition.find(:all, :conditions => 'state = 1')
      p_type = c.competitions_participants_type == 1 ? 'User' : 'Clan'
      
      if c.invitational?
        if c.competitions_participants_type == 1
          c.allowed_competitions_participants.create({:participant_id => u.id})
        else
          c.allowed_competitions_participants.create({:participant_id => clan.id})
        end
      end
      
      #if c.competitions_participants_type == 1
      #  p = c.competitions_participants.create({:participant_id => u.id, :name => u.login, :competitions_participants_type_id => c.competitions_participants_type_id, :roster => u.avatar})
      #else
      #  p = c.competitions_participants.create({:participant_id => clan.id, :name => clan.tag, :competitions_participants_type_id => c.competitions_participants_type_id, :roster => clan.competition_roster})
      #end
      get :join_competition, {:id => c.id}, {:user => 1}
      assert_response :redirect
      p = c.get_active_participant_for_user(u)
      assert c.competitions_participants.find(p.id)
      
      
      get :leave, {:id => c.id}, {:user => 1}
      assert_response :redirect
      
       (assert_equal orig_cash[p_type], p.the_real_thing.cash, "#{orig_cash[p_type]} vs #{p.the_real_thing.cash}") if c.fee?
      assert_raises(ActiveRecord::RecordNotFound) do
        c.competitions_participants.find(p.id)
      end
    end
  end
  
  def test_should_not_be_able_to_leave_if_state_not_1
    # TODO
    # c = Competition.find(:first, :conditions => 'state > 1')
    
    
  end
    
  def test_index
    get :index
    assert_response :success
  end
  
  def test_mapa
    get :mapa, :id => GamesMap.find(:first).id
    assert_response :success
  end
  
  def test_should_not_allow_to_show_competition_in_state_0
    c = Competition.find(:first, :conditions => 'state = 0')
    assert_not_nil c
    assert_raises(ActiveRecord::RecordNotFound) { get :show, :id => c.id }
  end
  
  def test_should_allow_to_see_index_of_competitions_when_not_in_state_0
    # lo hacemos con todas porque show tiene mucha funcionalidad
    # TODO no es completamente exhaustivo
    for c in Competition.find(:all, :conditions => 'state <> 0 and scoring_mode = 0') # el scoring_mode = 0 pq son innecesarios
      get :show, :id => c.id
      assert_response :success
    end
  end
  
  def test_should_not_allow_to_see_reglas_of_competitions_when_in_state_0
    c = Competition.find(:first, :conditions => 'state = 0')
    assert_not_nil c
    assert_raises(ActiveRecord::RecordNotFound) { get :reglas, :id => c.id }
  end
  
  def test_should_allow_to_see_reglas_of_competitions_when_not_in_state_0
    c = Competition.find(:first, :conditions => 'state > 0')
    assert_not_nil c
    get :reglas, :id => c.id
    assert_response :success
  end
  
  def test_should_not_allow_to_see_participantes_of_competitions_when_in_state_0
    c = Competition.find(:first, :conditions => 'state = 0')
    assert_not_nil c
    assert_raises(ActiveRecord::RecordNotFound) { get :reglas, :id => c.id }
  end
  
  def test_should_allow_to_see_participantes_of_competitions_when_not_in_state_0
    c = Competition.find(:first, :conditions => 'state > 0')
    assert_not_nil c
    get :participantes, :id => c.id
    assert_response :success
  end
  
  def test_should_not_allow_to_see_ranking_when_in_a_tournament
    c = Competition.find(:first, :conditions => 'state > 3 and type = \'Tournament\'')
    assert_not_nil c
    assert_raises(ActiveRecord::RecordNotFound) { get :ranking, :id => c.id }
  end
  
  def test_should_not_allow_to_see_ranking_when_in_a_ladder_not_started
    c = Competition.find(:first, :conditions => 'state < 3 and type = \'Ladder\'')
    assert_not_nil c
    assert_raises(ActiveRecord::RecordNotFound) { get :ranking, :id => c.id }
  end
  
  def test_should_not_allow_to_see_ranking_when_in_a_league_not_started
    c = Competition.find(:first, :conditions => 'state < 3 and type = \'League\'')
    assert_not_nil c
    assert_raises(ActiveRecord::RecordNotFound) { get :ranking, :id => c.id }
  end
  
  def test_should_allow_to_see_ranking_when_in_a_league
    c = Competition.find(:first, :conditions => 'state >= 3 and type = \'League\'')
    assert_not_nil c
    get :ranking, :id => c.id
    assert_response :success
  end
  
  def test_should_allow_to_see_ranking_when_in_a_ladder
    c = Competition.find(:first, :conditions => 'state >= 3 and type = \'Ladder\'')
    assert_not_nil c
    get :ranking, :id => c.id
    assert_response :success
  end
  
  def test_should_allow_to_see_partidas_when_in_a_ladder
    c = Competition.find(:first, :conditions => 'state >= 3 and type = \'Ladder\'')
    assert_not_nil c
    get :partidas, :id => c.id
    assert_response :success
  end
  
  def test_should_not_allow_to_see_partidas_when_not_in_a_ladder_and_not_in_state_3
    # TODO
  end
  
  def test_should_allow_to_see_partidas_when_not_in_a_ladder_and_in_state_gt_or_eq_3
    # TODO
  end
  
  # TODO test no challenging on non-ladders
  
  def test_should_show_challenge_page_when_challenging_participant
    test_should_be_able_to_join_if_state_3_and_ladder
    get :join_competition, {:id => @c.id}, {:user => 3}
    assert_response :redirect
    @u3 = User.find(3)
    assert_not_nil @c.get_active_participant_for_user(@u3)
    
    sym_login 2
    get :retar, { :id => @c.get_active_participant_for_user(@u3).id }
  end
  
  def test_should_be_able_to_challenge_user
    test_should_show_challenge_page_when_challenging_participant
    cm_count = @c.competitions_matches.count
    post :do_retar, { :id => @c.get_active_participant_for_user(@u3).id, :competitions_match => {:play_on => '', :servers =>  ''} }
    assert_response :redirect
    assert_equal cm_count + 1, @c.competitions_matches.count
  end
  
  def test_responder_reto
    test_should_be_able_to_challenge_user
    sym_login @u3.id
    get :responder_reto, { :id => @c.competitions_matches.find(:first, :order => 'id desc').id }
    assert_response :success
  end
  
    
  def test_cancelar_reto
    test_should_be_able_to_challenge_user
    cm = @c.competitions_matches.find(:first, :order => 'id desc')
    post :cancelar_reto, {:participant1_id => cm.participant1_id, :participant2_id => cm.participant2_id}
    assert_response :redirect
    assert_nil CompetitionsMatch.find_by_id(cm.id)
  end
    
  def test_do_accept_challenge
    test_should_be_able_to_challenge_user
    cm = @c.competitions_matches.find(:first, :order => 'id desc')
    sym_login @u3.id
    post :do_accept_challenge, :competitions_match_id => cm.id
    assert_response :redirect
    cm.reload
    assert cm.accepted
  end
  
  def test_do_deny_challenge
    test_should_be_able_to_challenge_user
    sym_login @u3.id
    cm = @c.competitions_matches.find(:first, :order => 'id desc')
    post :do_deny_challenge, :competitions_match_id => cm.id
    assert_response :redirect
    assert_nil CompetitionsMatch.find_by_id(cm.id)
  end
  
  def test_borrar_upload
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
  
  def test_nuevo_informe
    prepare_for_competitions_match_tests
    get :nuevo_informe, {:id => @cm.id }
    assert_response :success
  end
  
  def test_create_report
    test_nuevo_informe
    assert_count_increases(CompetitionsMatchesReport) do
      post :create_report, { :id => 1, :competitions_matches_report => { :report => 'po fale'}}
    end
    assert_response :redirect
  end
  
  def test_editar_informe
    test_create_report
    get :editar_informe, :id => CompetitionsMatchesReport.find(:first, :order => 'id desc').id
    assert_response :success
  end
  
  def test_update_report
    test_create_report
    cmr = CompetitionsMatchesReport.find(:first, :order => 'id desc')
    post :update_report, { :id => cmr.id, :competitions_matches_report => { :report => 'yolei'}}
    cmr.reload
    assert_equal 'yolei', cmr.report
    assert_response :redirect
  end
  
  def test_informe
    cmr = CompetitionsMatchesReport.find(:first)
    get :informe, :id => cmr.id
    assert_response :success
  end
  
  def test_upload_file
    prepare_for_competitions_match_tests
    assert_count_increases(CompetitionsMatchesUpload) do
      post :upload_file, { :id => 1, :competitions_matches_upload => { :file => fixture_file_upload('files/buddha.jpg', 'image/jpeg')}}
    end
  end
  
  def test_do_responder_reto
    # TODO
  end
  
  def test_retos_a_mi
    # TODO
  end
  
  def test_partida_shouldnt_work_if_competition_not_started
    cm = CompetitionsMatch.find(:first)
    User.db_query("UPDATE competitions set state = 1 where id = #{cm.competition_id}")
    assert_raises(ActiveRecord::RecordNotFound) { get :partida, :id => cm.id }
  end
  
  def test_partida_should_work_if_competition_started
    cm = CompetitionsMatch.find(:first)
    User.db_query("UPDATE competitions set state = 3 where id = #{cm.competition_id}")
    get :partida, :id => cm.id
    assert_response :success
  end
  
  def test_participante
    get :participante, :id => CompetitionsParticipant.find(:first).id
    assert_response :success
    # TODO faltan más condiciones para los tests
  end
  
  def test_confirmar_resultado
    # TODO
  end
end
