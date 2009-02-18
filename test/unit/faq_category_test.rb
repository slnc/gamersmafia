require File.dirname(__FILE__) + '/../test_helper'

class FaqCategoryTest < Test::Unit::TestCase

  def setup
    @faq_category = FaqCategory.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of FaqCategory,  @faq_category
  end
end
