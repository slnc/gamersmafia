# -*- encoding : utf-8 -*-
require 'test_helper'

class SoldFactionTest < ActiveSupport::TestCase

  test "_can_buy_faction_if_never_bought_before" do
  end

  def buy_a_faction
    u = User.find(1)
    p = Product.find_by_name('Facción')
    u.add_money(p.price)
    receipt = Shop::buy(p, u)
    assert_count_increases(Faction) do
      receipt.use({
          :code => 'awa',
          :name => 'Awander',
          :type => 'game',
      })
    end
    assert receipt.used?
  end

  test "_can_buy_faction_if_bought_not_recently" do
    buy_a_faction
    a_faction = SoldFaction.find(:first, :order => 'created_on')
    assert a_faction.update_attribute(:created_on, 4.months.ago)

    u = User.find(1)
    p = Product.find_by_name('Facción')
    u.add_money(p.price)
    receipt = Shop::buy(p, u)
    assert_count_increases(Faction) do
      receipt.use({
          :code => 'awi',
          :name => 'Awinder',
          :type => 'game',
      }) end
    assert receipt.used?
  end

  test "_can_buy_faction_if_not_banned_recently" do
    br = BanRequest.find(1)
    br.confirm(2)
    assert br.update_attributes(:unban_user_id => 1, :reason_unban => 'feo')
    br.confirm_unban(2)
    assert br.update_attributes({
        :confirmed_on => 7.months.ago,
        :unban_confirmed_on => 7.months.ago,
    })
    u = User.find(2) # ban_request 1 is for user_id 2
    p = Product.find_by_name('Facción')
    u.add_money(p.price)
    receipt = Shop::buy(p, u)
  end

  test "_cannot_buy_if_banned_recently" do
    br = BanRequest.find(1)
    br.confirm(2)
    assert br.update_attributes(:unban_user_id => 1, :reason_unban => 'feo')
    br.confirm_unban(2)
    u = User.find(2) # ban_request 1 is for user_id 2
    p = Product.find_by_name('Facción')
    u.add_money(p.price)
    assert_raises(AccessDenied) { receipt = Shop::buy(p, u) }
  end

  test "_cannot_buy_if_faction_bought_recently" do
    buy_a_faction
    u = User.find(1)
    p = Product.find_by_name('Facción')
    u.add_money(p.price)
    assert_raises(AccessDenied) { receipt = Shop::buy(p, u) }
  end

  test "create faction with wrong code" do
    u = User.find(1)
    p = Product.find_by_name('Facción')
    u.add_money(p.price)
    receipt = Shop::buy(p, u)
    assert_difference("Faction.count", 0) {
        receipt.use({
            :code => '%!$!',
            :name => 'Awander',
            :type => 'game',
        })
    }
    assert !receipt.used?
  end
end
