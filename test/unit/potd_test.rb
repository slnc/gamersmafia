# -*- encoding : utf-8 -*-
require 'test_helper'

class PotdTest < ActiveSupport::TestCase
  test "should_select_another_potd_if_current_potd_becomes_unpublished" do
    im = Image.published.first
    assert_not_nil im
    potd = Potd.new({:date => Time.now, :image_id => im.id})
    assert_equal true, potd.save

    im.change_state(Cms::DELETED, User.find(1))
    assert_nil Potd.find_by_id(potd.id)
    assert_equal false, im.is_public?
  end
end
