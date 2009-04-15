require File.dirname(__FILE__) + '/../test_helper'

class ContentTypeTest < ActiveSupport::TestCase

  def setup
    @content_type = ContentType.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ContentType,  @content_type
  end
end
