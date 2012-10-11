require 'test_helper'

class MiembrosHelperTest < ActionView::TestCase
  test "user_emblem_stats with nil emblems_mask" do
    u1 = User.find(1)
    u1.emblems_mask = ""
    user_emblem_stats(u1)
  end

  test "user_emblem_stats with emblems" do
    u1 = User.find(1)
    u1.emblems_mask = "1.0.0.0.1"
    assert_equal [["common", "1"], ["special", "1"]], user_emblem_stats(u1)
  end

  test "draw_karma_bar_sm less than 1k" do
    u1 = User.find(1)
    u1.cache_karma_points = 900
    assert draw_karma_bar_sm(u1).include?("900")
  end

  test "draw_karma_bar_sm thousands 1" do
    u1 = User.find(1)
    u1.cache_karma_points = 1000
    assert draw_karma_bar_sm(u1).include?("1,000")
  end

  test "draw_karma_bar_sm thousands 2" do
    u1 = User.find(1)
    u1.cache_karma_points = 1234
    assert draw_karma_bar_sm(u1).include?("1,234")
  end

  test "draw_karma_bar_sm tens of thousands1" do
    u1 = User.find(1)
    u1.cache_karma_points = 10000
    assert draw_karma_bar_sm(u1).include?("10.0k")
  end

  test "draw_karma_bar_sm tens of thousands2" do
    u1 = User.find(1)
    u1.cache_karma_points = 10001
    assert draw_karma_bar_sm(u1).include?("10.0k")
  end

  test "draw_karma_bar_sm tens of thousands3" do
    u1 = User.find(1)
    u1.cache_karma_points = 10100
    assert draw_karma_bar_sm(u1).include?("10.1k")
  end
end
