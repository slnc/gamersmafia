# -*- encoding : utf-8 -*-
require 'test_helper'

class ColumnTest < ActiveSupport::TestCase

  def setup
    @column = Column.find(1)
  end

  test "truth" do
    assert_kind_of Column,  @column
  end
end
