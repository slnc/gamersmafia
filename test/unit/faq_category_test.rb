# -*- encoding : utf-8 -*-
require 'test_helper'

class FaqCategoryTest < ActiveSupport::TestCase

  def setup
    @faq_category = FaqCategory.find(1)
  end

  test "truth" do
    assert_kind_of FaqCategory,  @faq_category
  end
end
