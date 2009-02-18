require File.dirname(__FILE__) + '/../test_helper'

class TutorialsCategoryTest < Test::Unit::TestCase

  def setup
    @tutorials_category = TutorialsCategory.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of TutorialsCategory,  @tutorials_category
  end
end
