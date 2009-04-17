require File.dirname(__FILE__) + '/../../../test/test_helper'
require File.dirname(__FILE__) + '/test_helper'

class HasBankAccountTest < ActiveSupport::TestCase
  def setup
    ActiveRecord::Base.db_query('CREATE TABLE has_bank_account_records (id serial primary key not null unique, name varchar, cash numeric(14,2) not null default 0)')
  end

  test "should_respond_to_expected_methods" do
    dummy = HasBankAccountRecord.new
    assert dummy.respond_to?(:remove_money)
    assert dummy.respond_to?(:add_money)
    assert dummy.respond_to?(:cash=)
  end

  test "crud" do
    d = HasBankAccountRecord.new({:name => 'foo'})
    assert true, d.save
    d = HasBankAccountRecord.find_by_name('foo')
    assert_not_nil d
    d.destroy
    assert d.frozen?
  end

  test "should_increment_money_if_added_money" do
    d = HasBankAccountRecord.create({:name => 'foo'})
    p_cash = d.cash
    d.add_money(1)
    assert d.cash == p_cash + 1
    d.reload
    assert d.cash == p_cash + 1
  end

  test "should_raise_error_if_trying_to_move_negative_ammount" do
    d = HasBankAccountRecord.create({:name => 'foo'})
    assert_raises(Bank::NegativeAmmountError) { d.add_money(-1) }
    assert_raises(Bank::NegativeAmmountError) { d.remove_money(-1) }
  end

  test "should_increment_money_if_remove_money" do
    d = HasBankAccountRecord.create({:name => 'foo'})
    p_cash = d.cash
    d.remove_money(1)
    assert d.cash == p_cash - 1
    d.reload
    assert d.cash == p_cash - 1
  end

  def teardown
    ActiveRecord::Base.db_query('DROP TABLE has_bank_account_records')
  end
end
