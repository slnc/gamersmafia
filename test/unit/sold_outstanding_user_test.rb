require 'test_helper'

class SoldOutstandingUserTest < ActiveSupport::TestCase

  DEF_OPTIONS = {:product_id => 1, :user_id => 1, :price_paid => 1}
  
  def test_should_buy_one_in_main_portal
    assert_count_increases(SoldOutstandingUser) { SoldOutstandingUser.create(DEF_OPTIONS) }
    s = SoldOutstandingUser.find(:first, :order => 'id DESC')
    assert_count_increases(Message) { assert_count_increases(OutstandingUser) { s.use({:portal_id => -1}) } }
    ou = OutstandingUser.find(:first, :order => 'id DESC')
    assert_equal 1.day.since.strftime('%Y%m%d'), ou.active_on.strftime('%Y%m%d')
  end
  
  def test_should_buy_one_in_factions_portal
    assert_count_increases(SoldOutstandingUser) { SoldOutstandingUser.create(DEF_OPTIONS) }
    s = SoldOutstandingUser.find(:first, :order => 'id DESC')
    assert_count_increases(OutstandingUser) { s.use({:portal_id => 1}) }
    ou = OutstandingUser.find(:first, :order => 'id DESC')
    assert_equal 1.day.since.strftime('%Y%m%d'), ou.active_on.strftime('%Y%m%d')
  end
  
  def test_should_buy_twice_in_factions_portal
    test_should_buy_one_in_main_portal
    assert_count_increases(SoldOutstandingUser) { SoldOutstandingUser.create(DEF_OPTIONS) }
    s = SoldOutstandingUser.find(:first, :order => 'id DESC')
    assert_count_increases(OutstandingUser) { s.use({:portal_id => -1}) }
    ou = OutstandingUser.find(:first, :order => 'id DESC')
    assert_equal 2.days.since.strftime('%Y%m%d'), ou.active_on.strftime('%Y%m%d')
  end
  
  def test_should_buy_two_in_main_portal_without_other_people_with_correct_spacing
    test_should_buy_one_in_main_portal
    assert_count_increases(SoldOutstandingUser) { SoldOutstandingUser.create(DEF_OPTIONS.merge(:user_id => 2)) }
    s = SoldOutstandingUser.find(:first, :order => 'id DESC')
    assert_count_increases(OutstandingUser) { s.use({:portal_id => -1}) }
    ou = OutstandingUser.find(:first, :order => 'id DESC')
    assert_equal 2.days.since.strftime('%Y%m%d'), ou.active_on.strftime('%Y%m%d')
    
    assert_count_increases(SoldOutstandingUser) { SoldOutstandingUser.create(DEF_OPTIONS) }
    s = SoldOutstandingUser.find(:first, :order => 'id DESC')
    assert_count_increases(OutstandingUser) { s.use({:portal_id => -1}) }
    ou = OutstandingUser.find(:first, :order => 'id DESC')
    assert_equal 3.days.since.strftime('%Y%m%d'), ou.active_on.strftime('%Y%m%d')
  end
  
  def test_should_buy_two_in_main_portal_with_other_people_with_correct_spacing

  end
end
