require File.dirname(__FILE__) + '/../../../test/test_helper'

class KarmaTest < Test::Unit::TestCase
  def test_should_give_karma_points_if_valid
    u = User.find(1)
    kp_initial = u.karma_points
    Karma.give(u, 1)
    assert_equal kp_initial + 1, u.karma_points
    u.reload
    assert_equal kp_initial + 1, u.karma_points
  end

  def test_should_take_karma_points_if_valid
    test_should_give_karma_points_if_valid
    u = User.find(1)
    kp_initial = u.karma_points
    Karma.take(u, 1)
    assert_equal kp_initial - 1, u.karma_points
    u.reload
    assert_equal kp_initial - 1, u.karma_points
  end

  def test_should_not_corrupt_karma_points_cache_due_to_concurrency
    u_a = User.find(1)
    u_b = User.find(1)
    kp_initial = u_a.karma_points
    Karma.give(u_a, 1)
    Karma.give(u_b, 1)
    assert_equal kp_initial + 1, u_a.karma_points # la primera instancia no tiene los datos frescos, ok, para eso usamos la cache
    assert_equal kp_initial + 2, u_b.karma_points
    u_a.reload
    u_b.reload
    assert_equal kp_initial + 2, u_a.karma_points
    assert_equal kp_initial + 2, u_b.karma_points
  end
  
  def test_update_ranking
    User.db_query("UPDATE users SET cache_karma_points = id")
    Karma.update_ranking
    assert_equal 1, User.find(1).ranking_karma_pos
    assert_equal 2, User.find(2).ranking_karma_pos
    assert_equal 3, User.find(3).ranking_karma_pos
  end
end
