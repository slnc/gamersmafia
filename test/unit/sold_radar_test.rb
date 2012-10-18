# -*- encoding : utf-8 -*-
require 'test_helper'

class SoldRadarTest < ActiveSupport::TestCase
  test "should_set_pref on creation" do
    @u = User.find(2)
    @p = Product.find_by_cls('SoldRadar')
    assert !@u.enable_radar_notifications?
    @u.add_money(@p.price)
    receipts_count = SoldProduct.count
    Shop::buy(@p, @u)
    @u.reload
    assert @u.enable_radar_notifications?
    assert_equal receipts_count + 1, SoldProduct.count
    receipt = SoldProduct.find(
        :first,
        :conditions => ['user_id = ? AND product_id = ?', @u.id, @p.id],
        :order => 'id DESC')
    assert_not_nil receipt
    assert receipt.used?
  end

  test "should_not_allow_to_buy_profile_signatures_twice" do
    test_should_set_pref_on_creation
    @u.add_money(@p.price)
    receipts_count = SoldProduct.count
    assert_raises(AccessDenied) { Shop::buy(@p, @u) }
    assert_equal receipts_count, SoldProduct.count
  end
end
