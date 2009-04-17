require 'test_helper'

class BetsTicketTest < ActiveSupport::TestCase
  def setup
    Bank::transfer(:bank, User.find(2), 100, 'test')
  end
  # Replace this with your real tests.
  def test_shouldnt_be_able_to_create_a_bet_ticket_with_less_than_min_ammount
    assert_raises (AmmountTooLow) do
      BetsTicket.create({:user_id => 2, :bets_option_id => 1, :ammount => 0.1})
    end
  end
  
  def test_should_be_able_to_create_a_bet_ticket_with_ammount_0
    @bt = BetsTicket.create({:user_id => 2, :bets_option_id => 1, :ammount => 0})
    assert_equal false, @bt.new_record?
  end

    def test_should_be_able_to_create_a_bet_ticket_with_min_ammount
    @bt = BetsTicket.create({:user_id => 2, :bets_option_id => 1, :ammount => BetsTicket::MIN_BET})
    assert_equal false, @bt.new_record?
  end
  
  def test_should_be_able_to_create_a_bet_ticket
    @bt = BetsTicket.create({:user_id => 2, :bets_option_id => 1, :ammount => BetsTicket::MIN_BET * 2})
    assert_equal false, @bt.new_record?
  end
  
  def test_should_be_able_to_change_an_initial_bet_to_0
    test_should_be_able_to_create_a_bet_ticket
    assert_equal true, @bt.update_ammount(0)
  end
  
  def test_should_be_able_to_change_an_initial_bet_to_more_than_the_initial_ammount
    test_should_be_able_to_create_a_bet_ticket
    assert_equal true, @bt.update_ammount(10)
    assert_equal 10.0, @bt.ammount
  end
  
  def test_shouldnt_be_able_to_lower_initial_ammount_to_less_than_min_ammount
    test_should_be_able_to_create_a_bet_ticket
    assert_raises (AmmountTooLow) { @bt.update_ammount(BetsTicket::MIN_BET - 1) }
  end
  
  def test_should_be_able_to_change_initial_bet_to_less_than_initial_ammount
    test_should_be_able_to_create_a_bet_ticket
    init = @bt.ammount
    assert_equal true, @bt.update_ammount(init - 1)
    assert_equal((init - 1), @bt.ammount)
  end
end
