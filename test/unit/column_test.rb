require File.dirname(__FILE__) + '/../test_helper'

class ColumnTest < Test::Unit::TestCase

  def setup
    @column = Column.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Column,  @column
  end
end
