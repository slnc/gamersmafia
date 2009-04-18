require 'test_helper'

class InterviewTest < ActiveSupport::TestCase

  def setup
    @interview = Interview.find(1)
  end

  # Replace this with your real tests.
  test "truth" do
    assert_kind_of Interview,  @interview
  end
end
