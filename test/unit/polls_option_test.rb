# -*- encoding : utf-8 -*-
require 'test_helper'

class PollsOptionTest < ActiveSupport::TestCase
  def setup
    @polls_option = PollsOption.find(1)
  end

  test "truth" do
    assert_kind_of PollsOption,  @polls_option
  end
end
