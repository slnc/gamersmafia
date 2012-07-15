# -*- encoding : utf-8 -*-
require "test_helper"

class CuentaCompeticionesControllerTestTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end


  test "should_create_working_tournament" do
    sym_login :superadmin, :lalala
    create_competition :type => 'Tournament', :name => 'FooTournament'
    go_to '/cuenta/competiciones/general'
    go_to '/cuenta/competiciones/configuracion'
    go_to '/cuenta/competiciones/partidas'
    go_to '/cuenta/competiciones/participantes'
    go_to '/cuenta/competiciones/admins'
  end

  test "should_create_working_ladder" do
    sym_login :superadmin, :lalala
    create_competition :type => 'Ladder', :name => 'FooLadder'
    go_to '/cuenta/competiciones/general'
    go_to '/cuenta/competiciones/configuracion'
    go_to '/cuenta/competiciones/partidas'
    go_to '/cuenta/competiciones/participantes'
    go_to '/cuenta/competiciones/admins'
  end

  test "should_create_working_league" do
    sym_login :superadmin, :lalala
    create_competition :type => 'League', :name => 'FooLeague'
    go_to '/cuenta/competiciones/general'
    go_to '/cuenta/competiciones/configuracion'
    go_to '/cuenta/competiciones/partidas'
    go_to '/cuenta/competiciones/participantes'
    go_to '/cuenta/competiciones/admins'
  end

  NEW_COMPETITION_DEFAULT_PARAMS = { :type => 'Tournament', :name => 'fooname', :game_id => 1, :competitions_participants_type_id => 1 }

  def create_competition(opts)
    go_to '/cuenta/competiciones/new'
    opts = NEW_COMPETITION_DEFAULT_PARAMS.merge(opts)
    prev = Competition.find_by_name(opts[:name])
    prev.destroy if prev
    post '/cuenta/competiciones/create', { :competition => opts }
    assert_response :redirect, response.body
    c = Competition.find_by_name(opts[:name])
    assert_not_nil c
    assert_equal 1, c.competitions_participants_type_id
  end

  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

end
