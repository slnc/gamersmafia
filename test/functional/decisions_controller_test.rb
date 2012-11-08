require 'test_helper'

class DecisionsControllerTest < ActionController::TestCase
  test "index" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "show" do
    sym_login 1
    get :show, :id => Decision.first.id
    assert_response :success
  end

  test "decide if initiating_user_id" do
    d6 = Decision.find(6)
    u5 = User.find(5)
    User.db_query("DELETE FROM decision_user_choices")
    winner = d6.decision_choices.last
    sym_login u5.id
    assert_raises(AccessDenied) do
      post :decide, {
        :id => Decision.first.id,
        :final_decision_choice => winner.id,
      }
    end
  end

  test "decide" do
    give_skill(2, "CreateTag")
    d6 = Decision.find(6)
    u2 = User.find(2)
    User.db_query("DELETE FROM decision_user_choices")
    sym_login u2.id
    winner = d6.decision_choices.last
    post :decide, {
      :id => Decision.first.id,
      :final_decision_choice => winner.id,
    }
    assert_response :success
    u2.reload
    assert_equal winner.id, u2.decision_user_choices.find_by_decision_id(d6.id).decision_choice_id
  end
end
