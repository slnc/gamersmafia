require File.dirname(__FILE__) + '/../test_helper'

class BetTest < Test::Unit::TestCase

  def setup
    @bet = Bet.create({:user_id => 1, :title => 'foo1 vs bar1', :bets_category_id => 1, :closes_on => 1.day.since})
    @bet.change_state(Cms::PUBLISHED, User.find(1))
    @bets_option_foo = @bet.bets_options.create({:name => 'foo'})
    @bets_option_bar = @bet.bets_options.create({:name => 'bar'})
    @bet.closes_on = 1.second.ago
    @bet.save
  end

  def prepare_first_three_users
    @u1 = User.find(1)
    @u2 = User.find(2)
    @u3 = User.find(3)
    Bank.transfer(:bank, @u1, 100, 't1')
    Bank.transfer(:bank, @u2, 100, 't2')
    Bank.transfer(:bank, @u3, 100, 't3')
    @u1.reload
    @u2.reload
    @u3.reload

    @cash_u1 = @u1.cash
    @cash_u2 = @u2.cash
    @cash_u3 = @u2.cash
  end


  def test_should_return_money_if_cancelled
    u1 = User.find(1)
    u2 = User.find(2)
    Bank.transfer(:bank, u1, 100 , 't1')
    Bank.transfer(:bank, u2, 100 , 't2')
    u1.reload
    u2.reload

    cash_u1 = u1.cash
    cash_u2 = u2.cash
    
    @bets_option_foo.bets_tickets.create({:user_id => 1, :ammount => BetsTicket::MIN_BET})
    @bets_option_bar.bets_tickets.create({:user_id => 1, :ammount => BetsTicket::MIN_BET})

    @bets_option_foo.bets_tickets.create({:user_id => 2, :ammount => BetsTicket::MIN_BET + 5})
    @bets_option_bar.bets_tickets.create({:user_id => 2, :ammount => BetsTicket::MIN_BET + 10})

    @bet.complete('cancelled')
    assert_equal true, @bet.completed?

    u1.reload
    u2.reload

    assert_equal cash_u1, u1.cash
    assert_equal cash_u2, u2.cash
  end


  def test_should_return_money_if_forfeit
    u1 = User.find(1)
    u2 = User.find(2)
    Bank.transfer(:bank, u1, 100 , 't1')
    Bank.transfer(:bank, u2, 100 , 't2')
    u1.reload
    u2.reload

    cash_u1 = u1.cash
    cash_u2 = u2.cash
    
    @bets_option_foo.bets_tickets.create({:user_id => 1, :ammount => BetsTicket::MIN_BET})
    @bets_option_bar.bets_tickets.create({:user_id => 1, :ammount => BetsTicket::MIN_BET})

    @bets_option_foo.bets_tickets.create({:user_id => 2, :ammount => BetsTicket::MIN_BET})
    @bets_option_bar.bets_tickets.create({:user_id => 2, :ammount => 8})

    @bet.complete('forfeit')
    assert_equal true, @bet.completed?

    u1.reload
    u2.reload

    assert_equal cash_u1, u1.cash
    assert_equal cash_u2, u2.cash
  end


  def test_should_properly_distribute_money_if_single_winner
    prepare_first_three_users
    
    @bets_option_foo.bets_tickets.create({:user_id => 1, :ammount => BetsTicket::MIN_BET})
    @bets_option_foo.bets_tickets.create({:user_id => 2, :ammount => BetsTicket::MIN_BET})
    @bets_option_bar.bets_tickets.create({:user_id => 2, :ammount => BetsTicket::MIN_BET})
    @bets_option_bar.bets_tickets.create({:user_id => 3, :ammount => BetsTicket::MIN_BET})

    @bet.complete(@bets_option_bar.id)
    
    assert_equal true, @bet.completed?

    @u1.reload
    @u2.reload
    @u3.reload

    assert_equal @cash_u1 - BetsTicket::MIN_BET.to_d, @u1.cash
    assert_equal @cash_u2, @u2.cash
    assert_equal @cash_u3 + BetsTicket::MIN_BET.to_d, @u3.cash
  end

  # opcion1 | opcion2
  #     100 |       0       (u1)
  #       0 |     100       (u2)
  def test_should_properly_distribute_money_if_tie_all_100pc_and_same_ammount
    prepare_first_three_users

    @bets_option_foo.bets_tickets.create({:user_id => 1, :ammount => 100})
    @bets_option_bar.bets_tickets.create({:user_id => 2, :ammount => 100})

    @bet.complete('tie')
    
    assert_equal true, @bet.completed?

    @u1.reload
    @u2.reload

    assert_equal @cash_u1, @u1.cash
    assert_equal @cash_u2, @u2.cash
  end

  # opcion1 | opcion2
  #      50 |       0       (u1)
  #       0 |     100       (u2)
  def test_should_properly_distribute_money_if_tie_all_100pc_and_different_ammount
    prepare_first_three_users

    @bets_option_foo.bets_tickets.create({:user_id => 1, :ammount => 50})
    @bets_option_bar.bets_tickets.create({:user_id => 2, :ammount => 100})

    @bet.complete('tie')
    
    assert_equal true, @bet.completed?

    @u1.reload
    @u2.reload

    assert_equal @cash_u1, @u1.cash
    assert_equal @cash_u2, @u2.cash
  end

  # opcion1 | opcion2
  #      50 |      50       (u1)
  #      50 |      50       (u2)
  def test_should_properly_distribute_money_if_tie_all_0pc_and_same_ammount
    prepare_first_three_users

    @bets_option_foo.bets_tickets.create({:user_id => 1, :ammount => 50})
    @bets_option_bar.bets_tickets.create({:user_id => 1, :ammount => 50})
    @bets_option_foo.bets_tickets.create({:user_id => 2, :ammount => 50})
    @bets_option_bar.bets_tickets.create({:user_id => 2, :ammount => 50})

    @bet.complete('tie')
    
    assert_equal true, @bet.completed?

    @u1.reload
    @u2.reload

    assert_equal @cash_u1, @u1.cash
    assert_equal @cash_u2, @u2.cash
  end
  

  # opcion1 | opcion2
  #      50 |      50       (u1)
  #      50 |      50       (u2)
  def test_should_properly_distribute_money_if_tie_all_0pc_and_mixed_ammounts
    prepare_first_three_users

    @bets_option_foo.bets_tickets.create({:user_id => 1, :ammount => 25})
    @bets_option_bar.bets_tickets.create({:user_id => 1, :ammount => 25})
    @bets_option_foo.bets_tickets.create({:user_id => 2, :ammount => 50})
    @bets_option_bar.bets_tickets.create({:user_id => 2, :ammount => 50})

    @bet.complete('tie')
    
    assert_equal true, @bet.completed?

    @u1.reload
    @u2.reload

    assert_equal @cash_u1, @u1.cash
    assert_equal @cash_u2, @u2.cash
  end

  # opcion1 | opcion2
  #     100 |       0       (u1)
  #      50 |      50       (u2)
  #      25 |      75       (u3)
  def test_should_properly_distribute_money_if_tie_mixed
    prepare_first_three_users

    @bets_option_foo.bets_tickets.create({:user_id => 1, :ammount => 100})
    @bets_option_foo.bets_tickets.create({:user_id => 2, :ammount => 50})
    @bets_option_bar.bets_tickets.create({:user_id => 2, :ammount => 50})
    @bets_option_foo.bets_tickets.create({:user_id => 3, :ammount => 25})
    @bets_option_bar.bets_tickets.create({:user_id => 3, :ammount => 75})
    
    @bet.complete('tie')
    
    assert_equal true, @bet.completed?

    @u1.reload
    @u2.reload
    @u3.reload
    
    assert_equal @cash_u1 - 100 + 29.54, @u1.cash
    assert_equal @cash_u2 - 100 + 186.55, @u2.cash
    assert_equal @cash_u3 - 100 + 83.90, @u3.cash
  end
end
