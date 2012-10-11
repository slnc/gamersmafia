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
end
