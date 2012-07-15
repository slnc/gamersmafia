# -*- encoding : utf-8 -*-
require 'test_helper'

class ContentRatingTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of ContentRating, ContentRating.find(:first)
  end
end
