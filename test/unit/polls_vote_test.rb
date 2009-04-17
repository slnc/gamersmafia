require 'test_helper'

class PollsVoteTest < ActiveSupport::TestCase

  def setup
    @polls_vote = PollsVote.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of PollsVote,  @polls_vote
  end
end
