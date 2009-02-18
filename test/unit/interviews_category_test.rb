require File.dirname(__FILE__) + '/../test_helper'

class InterviewsCategoryTest < Test::Unit::TestCase

  def setup
    @interviews_category = InterviewsCategory.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of InterviewsCategory,  @interviews_category
  end
end
