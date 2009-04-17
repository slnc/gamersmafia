require 'test_helper'

class SoldCommentsSigTest < ActiveSupport::TestCase
  test "should_enable_comments_sig_after_being_created" do
    @u = User.find(2)
    @p = Product.find_by_cls('SoldCommentsSig')
    assert_not_nil @u
    assert_not_nil @p
    assert !@u.enable_comments_sig?
    @u.add_money(@p.price)
    orig_cash = @u.cash
    receipts_count = SoldProduct.count
    Shop::buy(@p, @u)
    @u.reload
    assert @u.enable_comments_sig?
    assert_equal receipts_count + 1, SoldProduct.count
    receipt = SoldProduct.find(:first, :conditions => ['user_id = ? AND product_id = ?', @u.id, @p.id], :order => 'id DESC')
    assert_not_nil receipt
    assert receipt.used?
  end

  test "should_not_allow_to_buy_comments_sig_twice" do
    test_should_enable_comments_sig_after_being_created
    @u.add_money(@p.price)
    orig_cash = @u.cash
    receipts_count = SoldProduct.count
    assert_raises(AccessDenied) { Shop::buy(@p, @u) }
    assert_equal receipts_count, SoldProduct.count
  end
end
