require 'test_helper'

class TutorialTest < ActiveSupport::TestCase
  def setup
    @tutorial = Tutorial.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Tutorial,  @tutorial
  end
end
