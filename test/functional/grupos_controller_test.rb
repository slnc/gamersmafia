require File.dirname(__FILE__) + '/../test_helper'

class GruposControllerTest < ActionController::TestCase
  basic_test :index
  
  def test_group_without_being_member
    sym_login 1
    get :grupo, :id => 1
    assert_response :success
  end
  
  def test_group_being_member
    sym_login 1
    get :grupo, :id => 1
    assert_response :success
  end
  
  def test_group_being_owner
    assert Group.find(1).update_attributes(:owner_user_id => 1)
    test_group_being_member
  end
  
  def test_group_being_administrator
    assert Group.find(1).add_administrator(User.find(1))
    test_group_being_member
  end  
end
