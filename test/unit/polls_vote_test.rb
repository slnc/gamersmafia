require 'test_helper'

class PollsVoteTest < ActiveSupport::TestCase

  def setup
    @polls_vote = PollsVote.find(1)
  end

  test "truth" do
    assert_kind_of PollsVote,  @polls_vote
  end
end
