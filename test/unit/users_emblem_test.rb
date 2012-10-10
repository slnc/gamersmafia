# -*- encoding : utf-8 -*-
require 'test_helper'

class UsersEmblemTest < ActiveSupport::TestCase
  test "reset_emblems_mask" do
    u1 = User.find(1)
    assert_equal "0.0.0.0.0", u1.emblems_mask_or_calculate
    u1.users_emblems.create(:emblem => "comments_count_1")
    u1.reload
    assert_nil u1.emblems_mask
    assert_equal "1.0.0.0.0", u1.emblems_mask_or_calculate
  end
end
