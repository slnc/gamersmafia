require 'test_helper'

class DecisionUserReputationTest < ActiveSupport::TestCase
  test "recalculate_all_user_reputations" do
    DecisionUserReputation.recalculate_all_user_reputations
  end

  test "get_user_probability_for" do
    probability = DecisionUserReputation.get_user_probability_for(
        User.find(1), "CreateTag")
    assert_equal(0.3, probability)
  end

  test "update_probability_right" do
    u1 = User.find(1)
    d1 = Decision.find(6)
    winning_choice = u1.decision_user_choices.find(
        :first, :conditions => "decision_id = #{d1.id}")
    d1.update_attributes(
        :final_decision_choice_id => winning_choice.decision_choice_id,
        :state => Decision::DECIDED)

    rep1 = u1.decision_user_reputations.first
    rep1.update_probability_right
    assert_equal 1.0, rep1.probability_right
    assert_equal 1, rep1.all_time_right_choices
  end
end
