require 'test_helper'

class DecisionTest < ActiveSupport::TestCase
  test "choice_type_name" do
    Decision.first.choice_type_name
  end

  test "decision_description" do
    Decision.first.decision_description
  end

  test "completion_ratio" do
    assert_equal 1, Decision.first.completion_ratio
  end

  test "decision_binary" do
    Decision.first.binary?
  end

  test "try_to_decide" do
    decision = Decision.find(6)
    assert_difference("Term.count") do
      decision.try_to_decide
    end
    assert_equal Decision::DECIDED, decision.state
    assert_equal 7, decision.final_decision_choice_id
  end

  test "update_pending_decisions_indicators" do
    User.db_query("DELETE FROM decision_user_choices")
    u2 = User.find(2)
    u2.users_skills.create(:role => "CreateTag")
    Decision.update_pending_decisions_indicators
    u2.reload
    # No because no skill
    assert !User.find(1).pending_decisions
    # No because he is the initiating_user_id
    assert !User.find(5).pending_decisions
    # Yes because skill and not the initiating_user_id
    assert u2.pending_decisions
  end

  test "has_pending_decisions" do
    u5 = User.find(5)
    assert Decision.has_pending_decisions(u5)
  end

  test "update_pending_decisions_indicators for decision" do
    User.db_query("DELETE FROM decision_user_choices")
    u2 = User.find(2)
    u2.users_skills.create(:role => "CreateTag")
    d6 = Decision.find(6)
    d6.update_pending_decisions_indicators
    u2.reload
    # No because no skill
    assert !User.find(1).pending_decisions
    # No because he is the initiating_user_id
    assert !User.find(5).pending_decisions
    # Yes because skill and not the initiating_user_id
    assert u2.pending_decisions
  end
end
