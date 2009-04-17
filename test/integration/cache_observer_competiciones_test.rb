require 'test_helper'


class CacheObserverCompeticionesTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end
  
  # index#competiciones_en_curso
  def test_should_clear_cache_when_competition_advances_to_phase_3
    [Ladder, Tournament, League].each do |cls|
      l = cls.find(:first, :conditions => 'state = 2')
      assert_not_nil l
      get '/competiciones'
      assert_cache_exists "#{controller.portal.code}/competiciones/index/competiciones_en_curso"
      assert_equal true, l.switch_to_state(3)
      assert_cache_dont_exist "#{controller.portal.code}/competiciones/index/competiciones_en_curso"
    end
  end
  
  def test_should_clear_cache_when_competition_advances_to_phase_5
    [Ladder, Tournament, League].each do |cls|
      l = cls.find(:first, :conditions => 'state = 4')
      assert_not_nil l
      get '/competiciones'
      assert_cache_exists "#{controller.portal.code}/competiciones/index/competiciones_en_curso"
      assert_equal true, l.switch_to_state(5)
      assert_cache_dont_exist "#{controller.portal.code}/competiciones/index/competiciones_en_curso"
    end
  end
  
  def test_should_clear_cache_when_competition_in_phase_3_is_updated
    [Ladder, Tournament, League].each do |cls|
      l = cls.find(:first, :conditions => 'state = 3')
      assert_not_nil l
      get '/competiciones'
      assert_cache_exists "#{controller.portal.code}/competiciones/index/competiciones_en_curso"
      assert_equal true, l.save
      assert_cache_dont_exist "#{controller.portal.code}/competiciones/index/competiciones_en_curso"
    end
  end
  
  def test_should_clear_cache_competiciones_en_curso_when_competitions_match_is_completed
    #    l = Ladder.find(:first, :conditions => "state = 3 and competitions_participants_type_id = #{Competition::USERS}")
    #    u1 = User.find(1)
    #    u2 = User.find(2)
    #    p1 = l.join(u1)
    #    p2 = l.join(u2)
    #    cm = Competitions.challenge(p1,p2)
    #    cm.accept(p2)
    #    get '/competiciones'
    #    assert_cache_exists "#{controller.portal.code}/competiciones/index/competiciones_en_curso"
    #    assert_equal true, CompetitionsMatch.find(:first).save
    #    assert_cache_dont_exist "#{controller.portal.code}/competiciones/index/competiciones_en_curso"
  end
  
  def test_should_clear_cache_when_ladder_in_phase_3_receives_a_new_inscription
    sym_login 'superadmin', 'lalala'
    l = Ladder.find(:first, :conditions => 'state = 3 AND fee is null AND competitions_participants_type_id = 1 AND invitational is false')
    assert_not_nil l
    get '/competiciones'
    assert_cache_exists "#{controller.portal.code}/competiciones/index/competiciones_en_curso"
    post "/competiciones/join_competition/#{l.id}"
    assert_response :redirect, flash[:notice]
    assert_not_nil l.get_active_participant_for_user(User.find(1))
    assert_cache_dont_exist "#{controller.portal.code}/competiciones/index/competiciones_en_curso"
  end
  
  # index#competiciones_abiertas
  def test_should_clear_competiciones_abiertas_on_new_competition_enters_phase1
    [Ladder, Tournament, League].each do |cls|
      l = cls.find(:first, :conditions => 'state = 0')
      assert_not_nil l
      get '/competiciones'
      assert_cache_exists "#{controller.portal.code}/competiciones/index/inscripciones_abiertas"
      l.description = 'foo'
      assert_equal true, l.switch_to_state(1)
      assert_cache_dont_exist "#{controller.portal.code}/competiciones/index/inscripciones_abiertas"
    end
  end
  
  def test_should_clear_competiciones_abiertas_on_new_competition_leaves_phase1
    [Ladder, Tournament, League].each do |cls|
      l = cls.find(:first, :conditions => 'state = 1 and invitational is false and fee is null and competitions_participants_type_id = 1')
      assert_not_nil l
      get '/competiciones'
      assert_cache_exists "#{controller.portal.code}/competiciones/index/inscripciones_abiertas"
      logout
      sym_login 'superadmin', 'lalala'
      post "/competiciones/join_competition/#{l.id}"
      assert_response :redirect
      assert_nil flash[:error], flash[:error]
      assert_not_nil l.get_active_participant_for_user(User.find_by_login('superadmin'))
      logout
      sym_login 'panzer', 'lelele'
      post "/competiciones/join_competition/#{l.id}"
      assert_response :redirect, @response.body
      assert_nil flash[:error], flash[:error]
      assert_not_nil l.get_active_participant_for_user(User.find_by_login('panzer'))
      logout
      sym_login 'mrman', 'mrmanpass'
      post "/competiciones/join_competition/#{l.id}"
      assert_response :redirect, @response.body
      assert_nil flash[:error], flash[:error]
      assert_not_nil l.get_active_participant_for_user(User.find_by_login('mrman'))
      assert_equal true, l.switch_to_state(2)
      assert_cache_dont_exist "#{controller.portal.code}/competiciones/index/inscripciones_abiertas"
    end
  end
  
  def test_should_clear_competiciones_abiertas_on_competition_on_phase1_is_deleted
    [Ladder, Tournament, League].each do |cls|
      l = cls.find(:first, :conditions => 'state = 1')
      assert_not_nil l
      get '/competiciones'
      assert_cache_exists "#{controller.portal.code}/competiciones/index/inscripciones_abiertas"
      assert_not_nil l.destroy
      assert_nil cls.find_by_id(l.id)
      assert_cache_dont_exist "#{controller.portal.code}/competiciones/index/inscripciones_abiertas"
    end
  end
  
  def test_should_clear_competiciones_abiertas_on_competition_on_phase1_is_modified
    [Ladder, Tournament, League].each do |cls|
      l = cls.find(:first, :conditions => 'state = 1')
      assert_not_nil l
      get '/competiciones'
      assert_cache_exists "#{controller.portal.code}/competiciones/index/inscripciones_abiertas"
      assert_equal true, l.save
      assert_cache_dont_exist "#{controller.portal.code}/competiciones/index/inscripciones_abiertas"
    end
  end
  
  # index#competiciones_finalizadas
  def test_should_clear_competiciones_finalizadas_on_new_competition_enters_phase4
    [Ladder, Tournament, League].each do |cls|
      l = cls.find(:first, :conditions => 'state = 3')
      assert_not_nil l
      get '/competiciones'
      assert_cache_exists "#{controller.portal.code}/competiciones/index/competiciones_finalizadas"
      assert_equal true, l.switch_to_state(4)
      assert_cache_dont_exist "#{controller.portal.code}/competiciones/index/competiciones_finalizadas"
    end
  end
  
  def add_participants_to_l
    @u1 = User.find(1)
    @u2 = User.find(2)
    @p1 = @l.join(@u1)
    assert_not_nil @p1
    @p2 = @l.join(@u2)
    assert_not_nil @p2
  end
  
  
  def test_should_clear_competiciones_show_proximas_partidas_after_new_match_is_created
    @l = Ladder.find(:first, :conditions => "scoring_mode = #{Competition::SCORING_SIMPLE} and invitational is false and fee is null and state = 3 and competitions_participants_type_id = #{Competition::USERS}")
    add_participants_to_l
    cm = @l.challenge(@p1, @p2)
    assert_not_nil cm
    cm.accept_challenge
    get "/competiciones/show/#{@l.id}"
    assert_cache_exists "/common/competiciones/_show/#{@l.id}/proximas_partidas"
    assert_equal true, CompetitionsMatch.find(:first, :order => 'id DESC').save
    assert_cache_dont_exist "/common/competiciones/_show/#{@l.id}/proximas_partidas"
  end
  
  def test_should_clear_competiciones_show_ultimos_resultados_after_new_completed_match
    test_should_clear_competiciones_show_proximas_partidas_after_new_match_is_created
    @u1 = User.find(1)
    @l.add_admin(@u1)
    get "/competiciones/show/#{@l.id}"
    assert_cache_exists "/common/competiciones/_show/#{@l.id}/partidas_mas_recientes"
    cm = CompetitionsMatch.find(:first, :order => 'id DESC')
    assert_equal true, cm.complete_match(@u1, {:result => CompetitionsMatch::P1_WINS})
    assert_cache_dont_exist "/common/competiciones/_show/#{@l.id}/partidas_mas_recientes"
  end
  
  def test_should_clear_participante_retos_esperando_respuesta
    @l = Ladder.find(:first, :conditions => "scoring_mode = #{Competition::SCORING_SIMPLE} and invitational is false and fee is null and state = 3 and competitions_participants_type_id = #{Competition::USERS}")
    add_participants_to_l
    p2_cache_file = "/common/competiciones/participante/#{@p2.id % 1000}/#{@p2.id}/retos_esperando_respuesta"
    # Al principio no lo aceptamos
    get "/competiciones/participante/#{@p2.id}"
    assert_cache_exists p2_cache_file
    cm = @l.challenge(@p1, @p2)
    assert_not_nil cm
    assert_cache_dont_exist p2_cache_file 
    
    get "/competiciones/participante/#{@p2.id}"
    assert_cache_exists p2_cache_file 
    cm.reject_challenge
    assert_cache_dont_exist p2_cache_file 
    
    # Ahora sí lo aceptaremos
    get "/competiciones/participante/#{@p2.id}"
    assert_cache_exists p2_cache_file 
    cm = @l.challenge(@p1, @p2)
    assert_not_nil cm
    assert_cache_dont_exist p2_cache_file 
    
    get "/competiciones/participante/#{@p2.id}"
    assert_cache_exists p2_cache_file 
    cm.accept_challenge
    assert_cache_dont_exist p2_cache_file 
  end
  
  def test_should_clear_participante_retos_pendientes_de_jugar
    @l = Ladder.find(:first, :conditions => "scoring_mode = #{Competition::SCORING_SIMPLE} and invitational is false and fee is null and state = 3 and competitions_participants_type_id = #{Competition::USERS}")
    add_participants_to_l
    cm = @l.challenge(@p1, @p2)
    assert_not_nil cm
    cm.accept_challenge
    p1_cache_file = "/common/competiciones/participante/#{@p1.id % 1000}/#{@p1.id}/retos_pendientes_de_jugar"
    p2_cache_file = "/common/competiciones/participante/#{@p2.id % 1000}/#{@p2.id}/retos_pendientes_de_jugar"
    p1_cache_file2 = "/common/competiciones/participante/#{@p1.id % 1000}/#{@p1.id}/ultimas_partidas"
    p2_cache_file2 = "/common/competiciones/participante/#{@p2.id % 1000}/#{@p2.id}/ultimas_partidas"
    get "/competiciones/participante/#{@p1.id}"
    assert_cache_exists p1_cache_file
    assert_cache_exists p1_cache_file2
    
    get "/competiciones/participante/#{@p2.id}"
    assert_cache_exists p2_cache_file
    assert_cache_exists p2_cache_file2
    @l.add_admin(@u1)
    assert_equal true, cm.complete_match(@u1, {:result => CompetitionsMatch::P1_WINS})
    assert_cache_dont_exist p1_cache_file
    assert_cache_dont_exist p2_cache_file
    assert_cache_dont_exist p1_cache_file2
    assert_cache_dont_exist p2_cache_file2
    
  end
  
  # TODO faltan muchos más tests
  def test_should_clear_participants_last_maches_cache_after_completing_match
  end
  
  
  def teardown
    ActionController::Base.perform_caching             = false
  end
end
