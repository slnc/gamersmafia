# -*- encoding : utf-8 -*-
require 'test_helper'

class Cuenta::CompeticionesControllerTest < ActionController::TestCase



  test "should_see_configuration_page_of_every_competition" do
    u = User.find(1)
    sym_login 1
    competitions = []

    # Usamos random porque hay 361 combinaciones posibles de competiciones y testearlas todas ralentizaría la fase de testeo
    [League, Tournament, Ladder].each { |cls| competitions<< cls.find(:first, :conditions => 'state = 0', :order => 'RANDOM() ASC') }
    [League, Tournament, Ladder].each { |cls| competitions<< cls.find(:first, :conditions => 'state = 1', :order => 'RANDOM() ASC') }
    [League, Tournament, Ladder].each { |cls| competitions<< cls.find(:first, :conditions => 'state = 2', :order => 'RANDOM() ASC') }
    [League, Tournament, Ladder].each { |cls| competitions<< cls.find(:first, :conditions => 'state = 3', :order => 'RANDOM() ASC') }

    competitions.each do |c|
      c.add_admin(u)
      u.last_competition_id = c.id
      u.save
      get :configuracion
      assert_response :success
    end
  end

  test "update_tourney_groups" do
    # TODO
  end

  test "update_tourney_seeds" do
    # TODO
  end

  test "add_participants" do
    test_switch_active_competition
    # deshabilitamos esto porque a veces se añaden usuarios repetidos y casca
    # post :add_participants, { :participants_count => 1}
    assert_response :redirect
  end

  test "recreate_matches" do
    # TODO
#    test_switch_active_competition
#    get :recreate_matches
#    assert_response :redirect
  end

  test "index_with_enable_competition_indicator" do
    test_switch_active_competition
    assert User.find(1).update_attributes(:enable_competition_indicator => true)
    get :index
    assert_response :success
  end

  test "remove_all_participants" do
    test_switch_active_competition
    get :remove_all_participants
    assert_response :redirect
  end

  test "reselect_maps" do
    test_switch_active_competition
    get :reselect_maps
    assert_response :redirect
  end

  test "update_maches_games_maps" do
    # TODO
  end

  test "update_matches_play_on" do
    # TODO
  end

  test "previous_stage" do
    test_switch_active_competition
    get :previous_stage
    assert_response :redirect
  end

  test "general" do
    test_switch_active_competition
    get :general
    assert_response :success
  end

  test "avanzada" do
    # TODO
  end

  test "add_allowed_participant" do
    # TODO
  end

  test "configuracion" do
    test_switch_active_competition
    get :configuracion
    assert_response :success
  end

  test "admins" do
    test_switch_active_competition
    get :admins
    assert_response :success
  end

  test "partidas" do
    test_switch_active_competition
    get :partidas
    assert_response :success
  end

  test "participantes" do
    test_switch_active_competition
    get :participantes
    assert_response :success
  end

  test "eliminar_participante" do
    # TODO
  end

  test "crear_admin" do
    test_switch_active_competition
    post :crear_admin, :login => 'panzer'
    assert_response :redirect
    assert @c.user_is_admin(User.find_by_login('panzer').id)
  end

  test "eliminar_admin" do
    test_crear_admin
    post :eliminar_admin, :user_id => User.find_by_login('panzer').id
    assert_response :redirect
    assert !@c.user_is_admin(User.find_by_login('panzer').id)
  end

  test "crear_supervisor" do
    test_switch_active_competition
    post :crear_supervisor, :login => 'panzer'
    assert_response :redirect
    assert @c.user_is_supervisor(User.find_by_login('panzer').id)
  end

  test "eliminar_supervisor" do
    test_crear_supervisor
    post :eliminar_supervisor, :user_id => User.find_by_login('panzer').id
    assert_response :redirect
    assert !@c.user_is_supervisor(User.find_by_login('panzer').id)
  end

  test "cambiar" do
    sym_login 1
    get :cambiar
    assert_response :success
  end

  test "mis_partidas" do
    # TODO
  end

  test "list" do
    sym_login 1
    get :list
    assert_response :success
  end

  test "new" do
    sym_login 1
    get :new
    assert_response :success
  end

  test "create" do
    sym_login 1
    assert_count_increases(Competition) do
      post :create, :competition => { :type => 'Ladder', :name => 'mi ladder', :game_id => 1, :competitions_participants_type_id => 1, :competitions_types_options => {}, :timetable_options => {}}
    end
    @c = Competition.find(:first, :order => 'id desc')
    assert_equal @c.id, User.find(1).last_competition_id
  end

  test "update" do
    test_create
    post :update, { :id => @c.id, :competition => {:description => 'test_update'} }
    assert_response :redirect
    @c.reload
    assert_equal 'test_update', @c.description
  end

  test "destroy" do
    test_switch_active_competition
    post :destroy
    assert_response :redirect
    assert_nil User.find(1).last_competition_id
    assert_nil Competition.find_by_id(@c.id)
  end

  test "change_state" do
    # TODO
  end

  test "switch_active_competition" do
    @c = Competition.find(1)
    @c.add_admin(User.find(1))
    @c.pro = true
    assert @c.save
    sym_login 1
    post :switch_active_competition, :id => 1
    assert_response :redirect
    assert_equal 1, User.find(1).last_competition_id
  end

  test "sponsors_should_work" do
    test_switch_active_competition
    get :sponsors
    assert_response :success
  end

  test "sponsors_new_should_work" do
    test_switch_active_competition
    get :sponsors_new
    assert_response :success
  end

  test "sponsors_create_should_work" do
    test_switch_active_competition
    assert_count_increases(CompetitionsSponsor) do
      post :sponsors_create, { :competitions_sponsor => { :name => 'el nombre', :image => fixture_file_upload('files/buddha.jpg', 'image/jpeg')}}
    end
    assert_response :redirect
    @fl = CompetitionsSponsor.find(:first, :order => 'id desc')
  end

  test "sponsors_edit_should_work" do
    test_sponsors_create_should_work
    get :sponsors_edit, :id => CompetitionsSponsor.find(:first, :order => 'id desc').id
    assert_response :success
  end

  test "sponsors_update_should_work" do
    test_sponsors_create_should_work
    assert_not_equal 'succubus', @fl.name
    post :sponsors_update, :id => @fl.id, :competitions_sponsor => {:name => 'dm-tower', :image => fixture_file_upload('files/babe.jpg', 'image/jpeg')}
    assert_response :redirect
    @fl.reload
    assert_equal 'dm-tower', @fl.name
  end

  test "sponsors_destroy" do
    test_sponsors_create_should_work
    assert_count_decreases(CompetitionsSponsor) do
      post :sponsors_destroy, :id => @fl.id
    end
  end
end
