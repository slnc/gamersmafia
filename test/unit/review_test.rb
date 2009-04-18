require 'test_helper'

class ReviewTest < ActiveSupport::TestCase

  def setup
    @review = Review.find(1)
  end

  # Replace this with your real tests.
  test "truth" do
    assert_kind_of Review,  @review
  end
end
