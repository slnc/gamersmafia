require 'test_helper'

class InterviewTest < ActiveSupport::TestCase

  def setup
    @interview = Interview.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Interview,  @interview
  end
end
