# -*- encoding : utf-8 -*-
require 'test_helper'

class UserEmblemObserverTest < ActiveSupport::TestCase
  def post_comment(user)
    assert_difference("user.comments.count") do
      user.comments.create({
          :comment => "foo",
          :content_id => 1,
          :host => "127.0.0.1",
      })
    end
  end

  test "comments nothing" do
    u1 = User.find(1)
    self.override_threshold("T_COMMENTS_COUNT_1", 10) do
      self.post_comment(u1)
    end
    assert !u1.has_emblem?("comments_count_1")
  end

  test "comments comments_count_1" do
    self.ensure_comments_count_given(1)
  end

  test "comments comments_count_2" do
    self.ensure_comments_count_given(2)
  end

  test "comments comments_count_3" do
    self.ensure_comments_count_given(3)
  end

  def ensure_comments_count_given(level)
    u1 = User.find(1)
    current = u1.comments.karma_eligible.count
    self.override_threshold("T_COMMENTS_COUNT_#{level}", current + 1) do
      self.post_comment(u1)
    end
    assert u1.has_emblem?("comments_count_#{level}")
  end

  def override_threshold(threshold, value, &block)
    old_value = UsersEmblem.const_get(threshold)
    UsersEmblem.const_set(threshold, value)
    begin
      block.call
    rescue
      UsersEmblem.const_set(threshold, old_value)
      raise
    else
      UsersEmblem.const_set(threshold, old_value)
    end
  end

end
