require File.dirname(__FILE__) + '/../test_helper'

class ImagesCategoryTest < Test::Unit::TestCase

  def setup
    @images_category = ImagesCategory.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ImagesCategory,  @images_category
  end
end
