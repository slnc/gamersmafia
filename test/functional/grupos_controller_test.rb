require 'test_helper'

class GruposControllerTest < ActionController::TestCase
  basic_test :index

  test "group_without_being_member" do
    sym_login 1
    get :grupo, :id => 1
    assert_response :success
  end

  test "group_being_member" do
    sym_login 1
    get :grupo, :id => 1
    assert_response :success
  end

  test "group_being_owner" do
    assert Group.find(1).update_attributes(:owner_user_id => 1)
    test_group_being_member
  end

  test "group_being_administrator" do
    assert Group.find(1).add_administrator(User.find(1))
    test_group_being_member
  end
end
