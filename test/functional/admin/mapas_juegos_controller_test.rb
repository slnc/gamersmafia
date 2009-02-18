require File.dirname(__FILE__) + '/../../test_helper'

class Admin::MapasJuegosControllerTest < ActionController::TestCase
  def test_index
    get :index, {}, {:user => 1}
    assert_response :success
    assert_template 'index'
  end

  def test_new
    get :new, {}, {:user => 1}

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:games_map)
  end

  def test_create
    num_games_maps = GamesMap.count

    post :create, {:games_map => {:game_id => 1, :name => 'foo'}}, {:user => 1}

    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_equal num_games_maps + 1, GamesMap.count
  end

  def test_edit
    get :edit, {:id => 1}, {:user => 1}

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:games_map)
    assert assigns(:games_map).valid?
  end

  def test_update
    post :update, {:id => 1, :games_map =>  {}}, {:user => 1}
    assert_response :redirect
    assert_redirected_to :action => 'edit', :id => 1
  end

  def test_destroy
    assert_not_nil GamesMap.find(1)

    post :destroy, {:id => 1}, {:user => 1}
    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_raise(ActiveRecord::RecordNotFound) {
      GamesMap.find(1)
    }
  end
end
