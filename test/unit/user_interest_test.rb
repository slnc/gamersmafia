require 'test_helper'

class UserInterestTest < ActiveSupport::TestCase
  test "build_interest_profile" do
    UserInterest.build_interest_profile(User.find(1))
  end
end
