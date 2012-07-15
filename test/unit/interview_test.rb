# -*- encoding : utf-8 -*-
require 'test_helper'

class InterviewTest < ActiveSupport::TestCase

  def setup
    @interview = Interview.find(1)
  end

  test "truth" do
    assert_kind_of Interview,  @interview
  end
end
