require 'test_helper'

class CoverageTest < ActiveSupport::TestCase
  def test_shouldnt_work_if_missing_event
    en = Coverage.new({:state => Cms::PUBLISHED, :title => 'fooo events news'})
    assert_equal false, en.save
    assert_not_nil en.errors[:event_id]
  end
end
