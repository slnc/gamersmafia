require File.dirname(__FILE__) + '/../test_helper'

class SoldProfileSignaturesTest < ActiveSupport::TestCase
  def test_should_enable_profile_signatures_after_being_created
    @u = User.find(2)
    @p = Product.find_by_cls('SoldProfileSignatures')
    assert_not_nil @u
    assert_not_nil @p
    assert !@u.enable_profile_signatures?
    @u.add_money(@p.price)
    orig_cash = @u.cash
    receipts_count = SoldProduct.count
    Shop::buy(@p, @u)
    @u.reload
    assert @u.enable_profile_signatures?
    assert_equal receipts_count + 1, SoldProduct.count
    receipt = SoldProduct.find(:first, :conditions => ['user_id = ? AND product_id = ?', @u.id, @p.id], :order => 'id DESC')
    assert_not_nil receipt
    assert receipt.used?
  end

  def test_should_not_allow_to_buy_profile_signatures_twice
    test_should_enable_profile_signatures_after_being_created
    @u.add_money(@p.price)
    orig_cash = @u.cash
    receipts_count = SoldProduct.count
    assert_raises(AccessDenied) { Shop::buy(@p, @u) }
    assert_equal receipts_count, SoldProduct.count
  end
end
