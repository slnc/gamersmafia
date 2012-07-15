# -*- encoding : utf-8 -*-
require 'test_helper'

class ContentTypeTest < ActiveSupport::TestCase

  def setup
    @content_type = ContentType.find(1)
  end

  test "truth" do
    assert_kind_of ContentType,  @content_type
  end
end
