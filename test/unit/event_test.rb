require 'test_helper'

class EventTest < ActiveSupport::TestCase
  COMMON = { :user_id => 1, :approved_by_user_id => 1, :terms => 1, :state => Cms::PUBLISHED}
  
  def test_should_give_correct_hotmap1
    assert_not_nil Event.create(COMMON.merge({:title => 'fooe1', :starts_on => Time.local(2006, 01, 01, 00,00,00), :ends_on => Time.local(2006, 02, 06, 00,00,00)}))
    assert_not_nil Event.create(COMMON.merge({:title => 'fooe2', :starts_on => Time.local(2006, 02, 05, 00,00,00), :ends_on => Time.local(2006, 02, 10, 15,00,00)}))
    assert_not_nil Event.create(COMMON.merge({:title => 'fooe3', :starts_on => Time.local(2006, 02, 28, 00,00,00), :ends_on => Time.local(2006, 03, 05, 00,00,00)}))
    
    expected_hotmap = {1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 2, 6 => 2, 7 => 1, 8 => 1, 9 => 1, 10 => 1, 28 => 1}
    res_hotmap = Event.hotmap(Time.local(2006, 02, 15, 00,00,00))
    p res_hotmap
    res_hotmap.each do |k,v|
      puts k, v
      assert_equal v, expected_hotmap[k]
    end
  end
  
  def test_should_give_correct_hotmap2
    test_should_give_correct_hotmap1
    
    assert_not_nil Event.create(COMMON.merge({:title => 'fooe4', :starts_on => Time.local(2006, 02, 01, 00,00,00), :ends_on => Time.local(2006, 02, 06, 00,00,00)}))
    assert_not_nil Event.create(COMMON.merge({:title => 'fooe5', :starts_on => Time.local(2006, 02, 05, 00,00,00), :ends_on => Time.local(2006, 02, 11, 15,00,00)}))
    assert_not_nil Event.create(COMMON.merge({:title => 'fooe6', :starts_on => Time.local(2006, 02, 27, 00,00,00), :ends_on => Time.local(2006, 02, 28, 00,00,00)}))
    assert_not_nil Event.create(COMMON.merge({:title => 'fooe7', :starts_on => Time.local(2006, 02, 28, 00,00,00), :ends_on => Time.local(2006, 03, 01, 00,00,00)}))
    
    expected_hotmap = {27=>1, 5=>3, 11=>1, 28=>3, 6=>3, 1=>2, 7=>2, 2=>2, 8=>2, 3=>2, 9=>2, 4=>2, 10=>2}
    assert_equal expected_hotmap, Event.hotmap(Time.local(2006, 02, 15, 00,00,00))
  end
end
