require File.dirname(__FILE__) + '/../test_helper'

class SoldUserAvatarTest < Test::Unit::TestCase
  def test_should_create_custom_avatar_after_being_created
    u = User.find(1)
    p = Product.find(1)
    assert_not_nil u
    assert_not_nil p
    u.add_money(p.price)
    orig_cash = u.cash
    avatars_count = Avatar.count
    receipts_count = SoldProduct.count
    Shop::buy(p, u)
    assert_equal avatars_count + 1, Avatar.count
    assert_equal receipts_count + 1, SoldProduct.count
    receipt = SoldProduct.find(:first, :conditions => ['user_id = ? AND product_id = ?', u.id, p.id], :order => 'id DESC')
    assert_not_nil receipt
    assert receipt.used?
    last_avatar = Avatar.find(:first, :order => 'id DESC')
    assert_equal u.id, last_avatar.user_id
    assert_nil last_avatar.path
  end
end
