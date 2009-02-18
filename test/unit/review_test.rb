require File.dirname(__FILE__) + '/../test_helper'

class ReviewTest < Test::Unit::TestCase

  def setup
    @review = Review.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Review,  @review
  end
end
