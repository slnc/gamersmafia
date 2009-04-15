require File.dirname(__FILE__) + '/../../../test/test_helper'
require File.dirname(__FILE__) + '/test_helper'

class BankTest < ActiveSupport::TestCase
  def setup
    ActiveRecord::Base.db_query('CREATE TABLE has_bank_account_records (id serial primary key not null unique, name varchar, cash numeric(14,2) not null default 0)')
    @r1 = HasBankAccountRecord.create({:name => 'foo'})
    @r2 = HasBankAccountRecord.create({:name => 'bar'})
  end

  def test_should_properly_convert_karma_points_to_gmf
    assert_equal 0.2, Bank.convert(1, 'karma_points')
  end

  def test_should_properly_convert_faith_level_to_gmf
    assert_equal 0, Bank.convert(0, 'faith_level')
    assert_equal 5, Bank.convert(1, 'faith_level')
    assert_equal 15, Bank.convert(2, 'faith_level')
    assert_equal 35, Bank.convert(3, 'faith_level')
    assert_equal 75, Bank.convert(4, 'faith_level')
    assert_equal 100, Bank.convert(5, 'faith_level')
  end

  def test_should_not_convert_if_negative_ammount
    assert_raises(Bank::NegativeAmmountError) { Bank.convert(-1, 'karma_points') }
    assert_raises(Bank::NegativeAmmountError) { Bank.convert(-1, 'faith_level') }
  end

  def test_should_not_tranfer_if_blank_description
    r1_cash = @r1.cash
    r2_cash = @r2.cash
    assert_raises(Bank::TransferDescriptionError) { Bank.transfer(@r1, @r2, 1, '') }
    assert_raises(Bank::TransferDescriptionError) { Bank.transfer(@r1, @r2, 1, nil) }
    assert_raises(Bank::TransferDescriptionError) { Bank.transfer(@r1, @r2, 1, ' ') }
    assert_equal r1_cash, @r1.cash
    assert_equal r2_cash, @r2.cash
  end

  def test_should_not_tranfer_if_negative_ammount
    r1_cash = @r1.cash
    r2_cash = @r2.cash
    assert_raises(Bank::NegativeAmmountError) { Bank.transfer(@r1, @r2, -1, 'foo loves bar') }
    assert_equal r1_cash, @r1.cash
    assert_equal r2_cash, @r2.cash
  end

  def test_should_transfer_if_src_is_bank_but_dst_is_record
    r2_cash = @r2.cash
    Bank.transfer(:bank, @r2, 1, 'bank to bar')
    assert_equal r2_cash + 1, @r2.cash
  end

  def test_should_properly_calculate_cash_one_move_to
    Bank.transfer(:bank, @r2, 100, 'bank to bar')
    @r2.reload
    assert_equal sprintf("%.2f", @r2.cash), sprintf("%.2f", Bank.cash(@r2))
  end

  def test_should_properly_calculate_cash_one_move_from
    Bank.transfer(@r2, :bank, 25, 'bar to bank')
    @r2.reload
    assert_equal sprintf("%.2f", @r2.cash), sprintf("%.2f", Bank.cash(@r2))
  end

  def test_should_properly_calculate_cash_moves_both_ways
    Bank.transfer(:bank, @r2, 100, 'bank to bar')
    Bank.transfer(@r2, :bank, 25, 'bar to bank')
    @r2.reload
    assert_equal sprintf("%.2f", @r2.cash), sprintf("%.2f", Bank.cash(@r2))
  end

  def test_should_transfer_if_dst_is_bank_but_src_is_record
    r2_cash = @r2.cash
    Bank.transfer(@r2, :bank, 1, 'bar to bank')
    assert_equal r2_cash - 1, @r2.cash
  end

  def test_should_not_transfer_if_both_src_and_dst_are_bank
    assert_raises(Bank::IdenticalEntityError) { Bank.transfer(:bank, :bank, 1, 'bank to bank') }
  end

  def test_should_not_transfer_if_both_src_and_dst_are_the_same_record
    assert_raises(Bank::IdenticalEntityError) { Bank.transfer(@r1, @r1, 1, 'foo to foo') }
  end

  def test_should_transfer_if_both_src_and_dst_are_not_bank
    r1_cash = @r1.cash
    r2_cash = @r2.cash
    Bank.transfer(@r1, @r2, 1, 'foo to bar ')
    assert_equal r1_cash - 1, @r1.cash
    assert_equal r2_cash + 1, @r2.cash
  end

  def test_should_revert_existing_transfer_between_bank_and_dst
    r2_cash = @r2.cash
    test_should_transfer_if_src_is_bank_but_dst_is_record
    cm = CashMovement.find(:first, :order => 'id DESC')
    Bank.revert_transfer(cm)
    @r2.reload
    assert_equal r2_cash, @r2.cash
    assert_raises(ActiveRecord::RecordNotFound) { CashMovement.find(cm.id) } # esto comprueba que se ha cargado el movimiento
  end

  def test_should_revert_existing_transfer_between_src_and_bank
    r2_cash = @r2.cash
    test_should_transfer_if_dst_is_bank_but_src_is_record
    cm = CashMovement.find(:first, :order => 'id DESC')
    Bank.revert_transfer(cm)
    @r2.reload
    assert_equal r2_cash, @r2.cash
    assert_raises(ActiveRecord::RecordNotFound) { CashMovement.find(cm.id) } # esto comprueba que se ha cargado el movimiento
  end

  def test_should_revert_existing_transfer_between_src_and_dst_both_not_bank
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

  def test_should_revert_existing_transfer_id
    r1_cash = @r1.cash
    r2_cash = @r2.cash
    test_should_transfer_if_both_src_and_dst_are_not_bank
    Bank.revert_transfer(CashMovement.find(:first, :order => 'id DESC').id)
    @r1.reload
    @r2.reload
    assert_equal r1_cash, @r1.cash
    assert_equal r2_cash, @r2.cash
  end

  def test_should_log_if_transfer_correct
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

  def test_should_not_log_if_transfer_incorrect
    p = CashMovement.count
    test_should_not_transfer_if_both_src_and_dst_are_bank
    assert_equal p, CashMovement.count
  end

  def teardown
    ActiveRecord::Base.db_query('DROP TABLE has_bank_account_records')
  end
end
