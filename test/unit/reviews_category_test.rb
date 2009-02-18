require File.dirname(__FILE__) + '/../test_helper'

class ReviewsCategoryTest < Test::Unit::TestCase

  def setup
    @reviews_category = ReviewsCategory.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ReviewsCategory,  @reviews_category
  end
end
