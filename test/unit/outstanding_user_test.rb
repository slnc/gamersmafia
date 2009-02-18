require File.dirname(__FILE__) + '/../test_helper'

class OutstandingUserTest < Test::Unit::TestCase  
  def test_current_should_return_correct_user_case_a
    User.db_query("INSERT INTO stats.users_karma_daily_by_portal(user_id, portal_id, karma, created_on) VALUES(1, -1, 100, now())")
    bu = OutstandingUser.current(-1)
    assert_not_nil bu
    assert_equal 1, bu.entity_id
  end
  
  def test_current_should_return_correct_user_not_banned
    assert User.find(1).update_attributes(:state => User::ST_BANNED)
    User.db_query("INSERT INTO stats.users_karma_daily_by_portal(user_id, portal_id, karma, created_on) VALUES(1, -1, 100, now())")
    bu = OutstandingUser.current(-1)
    assert_nil bu
  end
  
  def test_current_should_return_correct_user_case_b
    test_current_should_return_correct_user_case_a
    User.db_query("UPDATE outstanding_entities set active_on = active_on - '1 day'::interval")
    User.db_query("INSERT INTO stats.users_karma_daily_by_portal(user_id, portal_id, karma, created_on) VALUES(2, -1, 50, now())")
    bu = OutstandingUser.current(-1)
    assert_not_nil bu
    assert_equal 2, bu.entity_id
  end
  
  def test_current_should_return_correct_user_case_c
    test_current_should_return_correct_user_case_a
    User.db_query("UPDATE outstanding_entities set active_on = active_on - '3 days'::interval")
    bu = OutstandingUser.current(-1)
    assert_not_nil bu
    assert_equal 1, bu.entity_id
  end
  
  def test_current_should_return_correct_user_case_d
    test_current_should_return_correct_user_case_a
    User.db_query("UPDATE stats.users_karma_daily_by_portal set created_on = created_on - '8 days'::interval")
    User.db_query("UPDATE outstanding_entities set active_on = active_on - '1 days'::interval")
    bu = OutstandingUser.current(-1)
    assert_nil bu
  end
end
