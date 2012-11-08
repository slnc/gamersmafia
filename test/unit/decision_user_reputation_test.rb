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
end
