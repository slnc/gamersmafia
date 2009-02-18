require File.dirname(__FILE__) + '/../test_helper'

class FaqEntryTest < Test::Unit::TestCase

  def setup
    @faq_entry = FaqEntry.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of FaqEntry,  @faq_entry
  end
end
