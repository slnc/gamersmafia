require 'test_helper'

class FaqCategoryTest < ActiveSupport::TestCase

  def setup
    @faq_category = FaqCategory.find(1)
  end

  # Replace this with your real tests.
  test "truth" do
    assert_kind_of FaqCategory,  @faq_category
  end
end
