# -*- encoding : utf-8 -*-
require 'test_helper'

class KarmaTest < ActiveSupport::TestCase
  test "should_give_karma_points_if_valid" do
    u = User.find(1)
    kp_initial = u.karma_points
    Karma.give(u, 1)
    assert_equal kp_initial + 1, u.karma_points
    u.reload
    assert_equal kp_initial + 1, u.karma_points
  end

  test "should_take_karma_points_if_valid" do
    test_should_give_karma_points_if_valid
    u = User.find(1)
    kp_initial = u.karma_points
    Karma.take(u, 1)
    assert_equal kp_initial - 1, u.karma_points
    u.reload
    assert_equal kp_initial - 1, u.karma_points
  end

  test "should_not_corrupt_karma_points_cache_due_to_concurrency" do
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

  test "update_ranking" do
    User.db_query("UPDATE users SET cache_karma_points = id")
    Karma.update_ranking
    assert_equal 17, User.find(1).ranking_karma_pos
    assert_equal 16, User.find(2).ranking_karma_pos
    assert_equal 15, User.find(3).ranking_karma_pos
  end
end
