require File.dirname(__FILE__) + '/../test_helper'

class TrackerItemTest < ActiveSupport::TestCase

  def setup
    @tracker_item = TrackerItem.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of TrackerItem,  @tracker_item
  end
end
