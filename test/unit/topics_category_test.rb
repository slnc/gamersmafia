require File.dirname(__FILE__) + '/../test_helper'

class TopicsCategoryTest < Test::Unit::TestCase

  def setup
    @forum_forum = TopicsCategory.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of TopicsCategory,  @forum_forum
  end
end
