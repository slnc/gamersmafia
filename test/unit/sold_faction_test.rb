require 'test_helper'

class SoldFactionTest < ActiveSupport::TestCase  
  def test_can_buy_faction_if_never_bought_before
    u = User.find(1)
    p = Product.find_by_name('Facción')
    u.add_money(p.price)
    receipt = Shop::buy(p, u)
    assert_count_increases(Faction) { receipt.use({:code => 'awa', :name => 'Awander', :type => 'game'}) }
    assert receipt.used?
  end
  
  def test_can_buy_faction_if_bought_not_recently
    test_can_buy_faction_if_never_bought_before
    assert SoldFaction.find(:first, :order => 'created_on').update_attributes(:created_on => 4.months.ago)
    
    u = User.find(1)
    p = Product.find_by_name('Facción')
    u.add_money(p.price)
    receipt = Shop::buy(p, u)
    assert_count_increases(Faction) { receipt.use({:code => 'awi', :name => 'Awinder', :type => 'game'}) }
    assert receipt.used?
  end
  
  def test_can_buy_faction_if_never_banned
    test_can_buy_faction_if_never_bought_before
  end
  
  def test_can_buy_faction_if_not_banned_recently
    br = BanRequest.find(1)
    br.confirm(2)
    assert br.update_attributes(:unban_user_id => 1, :reason_unban => 'feo')
    br.confirm_unban(2)
    assert br.update_attributes(:confirmed_on => 7.months.ago, :unban_confirmed_on => 7.months.ago)
    u = User.find(2) # ban_request 1 is for user_id 2
    p = Product.find_by_name('Facción')
    u.add_money(p.price)
    receipt = Shop::buy(p, u)
  end
  
  def test_cannot_buy_if_banned_recently
    br = BanRequest.find(1)
    br.confirm(2)
    assert br.update_attributes(:unban_user_id => 1, :reason_unban => 'feo')
    br.confirm_unban(2)
    u = User.find(2) # ban_request 1 is for user_id 2
    p = Product.find_by_name('Facción')
    u.add_money(p.price)
    assert_raises(AccessDenied) { receipt = Shop::buy(p, u) }
  end
  
  def test_cannot_buy_if_faction_bought_recently
    test_can_buy_faction_if_never_bought_before
     u = User.find(1)
    p = Product.find_by_name('Facción')
    u.add_money(p.price)
    assert_raises(AccessDenied) { receipt = Shop::buy(p, u) }
  end
end
