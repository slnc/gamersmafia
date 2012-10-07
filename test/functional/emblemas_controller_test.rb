require 'test_helper'

class EmblemasControllerTest < ActionController::TestCase
  test "index" do
    get :index
    assert_response :success
  end

  test "emblema no one" do
    get :emblema, :id => "comments_count_1"
    assert_response :success
  end

  test "emblema someone" do
    u1 = User.find(1)
    u1.users_emblems.create(:emblem => "comments_count_1")
    get :emblema, :id => "comments_count_1"
    assert_response :success
  end

end
