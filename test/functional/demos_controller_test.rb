require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'

class DemosControllerTest < ActionController::TestCase
  def setup
    @controller = DemosController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "arena.#{App.domain}"
  end
  
  DEF_VALS = {:entity1_external => 'foo', :games_mode_id => 1, :entity2_external => 'bar', :demotype => Demo::DEMOTYPES[:official], :mirrors_new => ["http://google.com/foo.zip", "http://kamasutra.com/porn.zip"] } 
  test_common_content_crud :name => 'Demo', :form_vars => DEF_VALS, :root_terms => [1] 
    
  def test_should_show_demo_page
    post :show, :id => Demo.find(:published, :limit => 1)[0].id
    assert_response :success    
  end
  
  def test_should_show_download_page
    d = Demo.find(:published, :limit => 1)[0]
    orig = d.downloaded_times
    post :download, :id => d.id
    assert_response :success
    d.reload
    assert_equal orig + 1, d.downloaded_times
  end
  
  def test_should_show_index
    post :index
    assert_response :success    
  end
  
  def test_buscar_should_redirect_if_nothing_given
    post :buscar
    assert_redirected_to '/demos'
  end
  
  def test_buscar_should_work_if_conditions_given
    post :buscar, { :demo => { :terms => 1 }}
    assert_response :success
  end
  
  def test_should_create_demo_with_references_to_local_if_checkbox_checked_and_user_entity_type
    sym_login 1
    opts = DEF_VALS.merge({:entity1_external => User.find(1).login, :entity1_is_local => '1'})
    # opts.delete :entity1_external
    
    assert_count_increases(Demo) do
      post :create, :demo => opts, :root_terms => [1]
    end
    
    d = Demo.find(:first, :order => 'id desc')
    assert_equal 1, d.entity1_local_id
    assert_equal User.find(1).login, d.entity1.login
  end
  
  def test_should_create_demo_with_references_to_local_if_checkbox_checked_and_clan_entity_type
    sym_login 1
    opts = DEF_VALS.merge({:entity2_external => Clan.find(1).name, :entity2_is_local => '1', :games_mode_id => 2})
    #    opts.delete :entity2_external
    
    assert_count_increases(Demo) do
      post :create, :demo => opts, :root_terms => [1]
    end
    
    d = Demo.find(:first, :order => 'id desc')
    assert_equal 1, d.entity2_local_id
    assert_equal Clan.find(1).name, d.entity2.name
  end
  
  def test_get_games_versions_should_work
    get :get_games_versions, :game_id => 1
    assert_response :success
  end
  
  def test_get_games_versions_shouldnt_crash_if_undefined_demos_category_id
    assert_raises(ActiveRecord::RecordNotFound) { get :get_games_versions }
  end
  
  def test_get_games_modes_should_work
    get :get_games_modes, :game_id => 1
    assert_response :success
  end
  
  def test_get_games_modes_shouldnt_crash_if_undefined_demos_category_id
    assert_raises(ActiveRecord::RecordNotFound) { get :get_games_modes }
  end
  
  def test_get_games_maps_should_work
    get :get_games_maps, :game_id => 1
    assert_response :success
  end
  
  def test_get_games_maps_shouldnt_crash_if_undefined_demos_category_id
    assert_raises(ActiveRecord::RecordNotFound) { get :get_games_maps }
  end
end
