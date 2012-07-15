# -*- encoding : utf-8 -*-
require 'test_helper'

class TutorialTest < ActiveSupport::TestCase
  def setup
    @tutorial = Tutorial.find(1)
  end

  test "truth" do
    assert_kind_of Tutorial,  @tutorial
  end
end
