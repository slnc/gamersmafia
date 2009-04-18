require 'test_helper'

class ColumnTest < ActiveSupport::TestCase

  def setup
    @column = Column.find(1)
  end

  # Replace this with your real tests.
  test "truth" do
    assert_kind_of Column,  @column
  end
end
