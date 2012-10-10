# -*- encoding : utf-8 -*-
require 'test_helper'

class HasBankAccountRecord < ActiveRecord::Base
  has_bank_account
end

class BankTest < ActiveSupport::TestCase
  def setup
    ActiveRecord::Base.db_query('CREATE TABLE has_bank_account_records (id serial primary key not null unique, name varchar, cash numeric(14,2) not null default 0)')
    @r1 = HasBankAccountRecord.create({:name => 'foo'})
    @r2 = HasBankAccountRecord.create({:name => 'bar'})
  end

  test "should_properly_convert_karma_points_to_gmf" do
    assert_equal 1, Bank.convert(1, 'karma_points')
  end

  test "should_not_convert_if_negative_ammount" do
    assert_raises(Bank::NegativeAmmountError) { Bank.convert(-1, 'karma_points') }
  end

  test "should_not_tranfer_if_blank_description" do
    r1_cash = @r1.cash
    r2_cash = @r2.cash
    assert_raises(Bank::TransferDescriptionError) { Bank.transfer(@r1, @r2, 1, '') }
    assert_raises(Bank::TransferDescriptionError) { Bank.transfer(@r1, @r2, 1, nil) }
    assert_raises(Bank::TransferDescriptionError) { Bank.transfer(@r1, @r2, 1, ' ') }
    assert_equal r1_cash, @r1.cash
    assert_equal r2_cash, @r2.cash
  end

  test "should_not_tranfer_if_negative_ammount" do
    r1_cash = @r1.cash
    r2_cash = @r2.cash
    assert_raises(Bank::NegativeAmmountError) { Bank.transfer(@r1, @r2, -1, 'foo loves bar') }
    assert_equal r1_cash, @r1.cash
    assert_equal r2_cash, @r2.cash
  end

  test "should_transfer_if_src_is_bank_but_dst_is_record" do
    r2_cash = @r2.cash
    Bank.transfer(:bank, @r2, 1, 'bank to bar')
    assert_equal r2_cash + 1, @r2.cash
  end

  test "should_properly_calculate_cash_one_move_to" do
    Bank.transfer(:bank, @r2, 100, 'bank to bar')
    @r2.reload
    assert_equal sprintf("%.2f", @r2.cash), sprintf("%.2f", Bank.cash(@r2))
  end

  test "should_properly_calculate_cash_one_move_from" do
    Bank.transfer(@r2, :bank, 25, 'bar to bank')
    @r2.reload
    assert_equal sprintf("%.2f", @r2.cash), sprintf("%.2f", Bank.cash(@r2))
  end

  test "should_properly_calculate_cash_moves_both_ways" do
    Bank.transfer(:bank, @r2, 100, 'bank to bar')
    Bank.transfer(@r2, :bank, 25, 'bar to bank')
    @r2.reload
    assert_equal sprintf("%.2f", @r2.cash), sprintf("%.2f", Bank.cash(@r2))
  end

  test "should_transfer_if_dst_is_bank_but_src_is_record" do
    r2_cash = @r2.cash
    Bank.transfer(@r2, :bank, 1, 'bar to bank')
    assert_equal r2_cash - 1, @r2.cash
  end

  test "should_not_transfer_if_both_src_and_dst_are_bank" do
    assert_raises(Bank::IdenticalEntityError) do
      Bank.transfer(:bank, :bank, 1, 'bank to bank')
    end
  end

  test "should_not_transfer_if_both_src_and_dst_are_the_same_record" do
    assert_raises(Bank::IdenticalEntityError) { Bank.transfer(@r1, @r1, 1, 'foo to foo') }
  end

  test "should_transfer_if_both_src_and_dst_are_not_bank" do
    r1_cash = @r1.cash
    r2_cash = @r2.cash
    Bank.transfer(@r1, @r2, 1, 'foo to bar ')
    assert_equal r1_cash - 1, @r1.cash
    assert_equal r2_cash + 1, @r2.cash
  end

  test "should_revert_existing_transfer_between_bank_and_dst" do
    r2_cash = @r2.cash
    test_should_transfer_if_src_is_bank_but_dst_is_record
    cm = CashMovement.find(:first, :order => 'id DESC')
    Bank.revert_transfer(cm)
    @r2.reload
    assert_equal r2_cash, @r2.cash
    assert_raises(ActiveRecord::RecordNotFound) { CashMovement.find(cm.id) } # esto comprueba que se ha cargado el movimiento
  end

  test "should_revert_existing_transfer_between_src_and_bank" do
    r2_cash = @r2.cash
    test_should_transfer_if_dst_is_bank_but_src_is_record
    cm = CashMovement.find(:first, :order => 'id DESC')
    Bank.revert_transfer(cm)
    @r2.reload
    assert_equal r2_cash, @r2.cash
    assert_raises(ActiveRecord::RecordNotFound) { CashMovement.find(cm.id) } # esto comprueba que se ha cargado el movimiento
  end

  test "should_revert_existing_transfer_between_src_and_dst_both_not_bank" do
    r1_cash = @r1.cash
    r2_cash = @r2.cash
    test_should_transfer_if_both_src_and_dst_are_not_bank
    cm = CashMovement.find(:first, :order => 'id DESC')
    Bank.revert_transfer(cm)
    @r1.reload
    @r2.reload
    assert_equal r1_cash, @r1.cash
    assert_equal r2_cash, @r2.cash
    assert_raises(ActiveRecord::RecordNotFound) { CashMovement.find(cm.id) } # esto comprueba que se ha cargado el movimiento
  end

  test "should_revert_existing_transfer_id" do
    r1_cash = @r1.cash
    r2_cash = @r2.cash
    test_should_transfer_if_both_src_and_dst_are_not_bank
    Bank.revert_transfer(CashMovement.find(:first, :order => 'id DESC').id)
    @r1.reload
    @r2.reload
    assert_equal r1_cash, @r1.cash
    assert_equal r2_cash, @r2.cash
  end

  test "should_log_if_transfer_correct" do
    p = CashMovement.count
    test_should_transfer_if_both_src_and_dst_are_not_bank
    assert_equal p + 1, CashMovement.count
    le = CashMovement.find(:first, :order => 'id DESC')
    assert_equal @r1.id, le.object_id_from
    assert_equal @r1.class.name, le.object_id_from_class
    assert_equal @r2.id, le.object_id_to
    assert_equal @r2.class.name, le.object_id_to_class
    assert_equal 1.0, le.ammount
    assert_equal 'foo to bar', le.description
  end

  test "should_not_log_if_transfer_incorrect" do
    p = CashMovement.count
    test_should_not_transfer_if_both_src_and_dst_are_bank
    assert_equal p, CashMovement.count
  end

  def teardown
    ActiveRecord::Base.db_query('DROP TABLE has_bank_account_records')
  end
end
