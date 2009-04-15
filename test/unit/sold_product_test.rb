require File.dirname(__FILE__) + '/../test_helper'

class SoldProductTest < ActiveSupport::TestCase
  def test_should_remove_money_when_buying_a_product
    u = User.find(1)
    p = Product.find(1)
    assert_not_nil u
    assert_not_nil p
    u.add_money(p.price)
    orig_cash = u.cash
    # p.buy(u)
    Shop::buy(p, u)
    assert_not_nil p.sold_products.find(:first, :conditions => ['user_id = ? ', u.id])
    u.reload
    assert_equal orig_cash - p.price, u.cash
  end
end
