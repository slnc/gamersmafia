require File.dirname(__FILE__) + '/../test_helper'

class PollsOptionTest < Test::Unit::TestCase
  def setup
    @polls_option = PollsOption.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of PollsOption,  @polls_option
  end
end
