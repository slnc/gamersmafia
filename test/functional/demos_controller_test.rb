require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'

class DemosControllerTest < ActionController::TestCase
  def setup
    @request.host = "arena.#{App.domain}"
  end

  DEF_VALS = {
               :demotype => Demo::DEMOTYPES[:official],
               :entity1_external => 'foo',
               :entity2_external => 'bar',
               :games_mode_id => 1,
               :mirrors_new => ["http://google.com/foo.zip", "http://kamasutra.com/porn.zip"]
             }

  test_common_content_crud :form_vars => DEF_VALS, :name => 'Demo', :root_terms => [1]

  test "should_show_demo_page" do
    post :show, :id => Demo.published.find(:all, :limit => 1)[0].id
    assert_response :success
  end

  test "should_show_download_page" do
    d = Demo.published.find(:all, :limit => 1)[0]
    orig = d.downloaded_times
    post :download, :id => d.id
    assert_response :success
    d.reload
    assert_equal orig + 1, d.downloaded_times
  end

  test "buscar_should_redirect_if_nothing_given" do
    post :buscar
    assert_redirected_to '/demos'
  end

  test "buscar_should_work_if_only_demo_term_id_condition_given" do
    post :buscar, { :demo_term_id => '1'}
    assert_response :success
  end

  test "buscar_should_work_if_conditions_given" do
    post :buscar, { :demo => { :demotype => '',
                               :entity => '',
                               :event_id => '',
                               :pov_type => '',
                             },
                    :demo_term_id => '1'
                  }
    assert_response :success
  end

  test "should_create_demo_with_references_to_local_if_checkbox_checked_and_user_entity_type" do
    sym_login 1
    opts = DEF_VALS.merge(:entity1_external => User.find(1).login,
                          :entity1_is_local => '1')

    assert_count_increases(Demo) do
      post :create, :demo => opts, :root_terms => [1]
    end

    d = Demo.find(:first, :order => 'id desc')
    assert_equal 1, d.entity1_local_id
    assert_equal User.find(1).login, d.entity1.login
  end

  test "should_create_demo_with_references_to_local_if_checkbox_checked_and_clan_entity_type" do
    sym_login 1
    opts = DEF_VALS.merge(:entity2_external => Clan.find(1).name,
                          :entity2_is_local => '1',
                          :games_mode_id => 2)

    assert_count_increases(Demo) do
      post :create, :demo => opts, :root_terms => [1]
    end

    d = Demo.find(:first, :order => 'id desc')
    assert_equal 1, d.entity2_local_id
    assert_equal Clan.find(1).name, d.entity2.name
  end

  test "get_games_versions_should_work" do
    get :get_games_versions, :game_id => 1
    assert_response :success
  end

  test "get_games_versions_shouldnt_crash_if_undefined_demos_term_id" do
    assert_raises(ActiveRecord::RecordNotFound) { get :get_games_versions }
  end

  test "get_games_modes_should_work" do
    get :get_games_modes, :game_id => 1
    assert_response :success
  end

  test "get_games_modes_shouldnt_crash_if_undefined_demos_term_id" do
    assert_raises(ActiveRecord::RecordNotFound) { get :get_games_modes }
  end

  test "get_games_maps_should_work" do
    get :get_games_maps, :game_id => 1
    assert_response :success
  end

  test "get_games_maps_shouldnt_crash_if_undefined_demos_category_id" do
    assert_raises(ActiveRecord::RecordNotFound) { get :get_games_maps }
  end
end
