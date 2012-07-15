# -*- encoding : utf-8 -*-
require 'test_helper'

class CoverageTest < ActiveSupport::TestCase
  test "shouldnt_work_if_missing_event" do
    en = Coverage.new({:state => Cms::PUBLISHED, :title => 'fooo events news'})
    assert_equal false, en.save
    assert_not_nil en.errors[:event_id]
  end
end
