require File.dirname(__FILE__) + '/../test_helper'

class ColumnsCategoryTest < Test::Unit::TestCase

  def setup
    @columns_category = ColumnsCategory.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ColumnsCategory,  @columns_category
  end
end
