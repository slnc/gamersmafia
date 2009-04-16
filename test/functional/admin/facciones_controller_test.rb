require 'test_helper'

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
  
  def test_delete_works
    sym_login 1
    g = Game.new(:name => 'faccionita', :code => 'code')
    assert g.save, g.errors.full_messages_html
    f = Faction.find_by_code(g.code)
    assert Portal.find_by_code(f.code)
    post :destroy, :id => f.id
    assert_response :redirect
    assert Faction.find_by_id(f.id).nil?
    assert Portal.find_by_code(f.code).nil?
  end
end
