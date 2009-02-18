require File.dirname(__FILE__) + '/../../test_helper'

class Admin::FaccionesControllerTest < ActionController::TestCase

  def test_index_should_work
    sym_login 1
    get :index
    assert_response :success
  end
  
  def test_edit_should_work
    sym_login 1
    get :edit, { :id => 1}
    assert_response :success
  end
  
  def test_update_works
    sym_login 1
    f = Faction.find(:first)
    n = f.name
    assert_not_nil f
    post :update, { :id => f.id, :faction => { :name => "#{n} a",  :building_top => '', :building_middle => '', :building_bottom => '' }}
    assert_response :redirect
    f.reload
    assert_equal "#{n} a", f.name
  end
end
