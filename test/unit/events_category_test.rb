require File.dirname(__FILE__) + '/../test_helper'

class EventsCategoryTest < Test::Unit::TestCase

  def setup
    @events_category = EventsCategory.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of EventsCategory,  @events_category
  end
end
