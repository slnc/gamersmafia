require 'test_helper'

class Admin::CompeticionesControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :info ]
  
  def test_index
    sym_login :superadmin
    get :index
    assert_response :success
    assert_template 'index'
  end
  
  def test_info
    sym_login :superadmin
    get :info, :id => Competition.find(:first)
    assert_response :success
    assert_template 'info'
  end
  
  def test_info_should_raise_404_if_nonexistent
    sym_login :superadmin
    assert_raises(ActiveRecord::RecordNotFound) { get :info, :id => 0 }
  end
  
  def test_should_delete_unstarted_competition
    sym_login :superadmin
    todel = Competition.find(:first, :conditions => "state = #{Competition::CREATED}")
    assert_not_nil todel
    post :destroy, :id => todel.id
    assert_redirected_to '/admin/competiciones'
    assert_nil Competition.find_by_id(todel.id)
  end
end
