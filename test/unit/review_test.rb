# -*- encoding : utf-8 -*-
require 'test_helper'

class ReviewTest < ActiveSupport::TestCase

  def setup
    @review = Review.find(1)
  end

  test "truth" do
    assert_kind_of Review,  @review
  end
end
