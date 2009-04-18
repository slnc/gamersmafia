require 'test_helper'

class SoldChangeNickTest < ActiveSupport::TestCase
  test "should_create_nick_change_entry_on_usage" do
    u = User.find(1)
    p = Product.find_by_name('Cambio de nick')
    assert_not_nil u
    assert_not_nil p
    u.add_money(p.price)
    orig_cash = u.cash
    receipt = Shop::buy(p, u)
    assert_not_nil receipt
    assert_count_increases(UserLoginChange) { receipt.use({:nuevo_login => 'Awajujija'}) }
    assert receipt.used?
    u.reload
    assert_equal 'Awajujija', u.login
    
  end
end
