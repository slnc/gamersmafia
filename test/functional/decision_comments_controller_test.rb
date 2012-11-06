require 'test_helper'

class DecisionCommentsControllerTest < ActionController::TestCase
  test "shouldnt post create for initiating_user_id" do
    sym_login 5
    d6 = Decision.find(6)
    assert_raises(AccessDenied) do
      post :create, {
        :decision_id => 6,
        :comment => "Hallo",
      }
    end
  end

  test "should post create for nont initiating_user_id" do
    give_skill(2, "CreateTag")
    sym_login 2
    d6 = Decision.find(6)
    assert_difference("d6.decision_comments.count") do
      post :create, {
        :decision_id => 6,
        :comment => "Hallo",
      }
    end
  end

  test "shouldnt create comment if missing field" do
    give_skill(2, "CreateTag")
    sym_login 2
    d6 = Decision.find(6)
    assert_difference("d6.decision_comments.count", 0) do
      post :create, {
        :decision_id => 6,
      }
      assert_response :success
    end
  end

  test "comments_index" do
    get :index, :decision_id => 6
    assert_response :success
  end
end
