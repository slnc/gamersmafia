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

  test "the_beast" do
    u1 = User.find(1)
    assert !u1.has_emblem?("the_beast")
    u1.update_attribute(
        :cache_karma_points, UsersEmblem::T_THE_BEAST_KARMA_POINTS)
    u1.reload
    assert u1.has_emblem?("the_beast")
  end

  test "comments_valorations_1" do
    u2 = User.find(56)
    assert !u2.has_emblem?("comments_valorations_1")
    assert_difference("u2.comments_valorations.count") do
      u2.comments_valorations.create(
          :comment_id => 1, :comments_valorations_type_id => 1, :weight => 0.3)
    end
    u2.reload
    assert u2.has_emblem?("comments_valorations_1")
  end

  test "comments_valorations_2" do
    self.ensure_comments_valorations_given(2)
  end

  test "comments_valorations_3" do
    self.ensure_comments_valorations_given(3)
  end

  def ensure_comments_valorations_given(level)
    # 3 people, u1 and u2 rate same comments as u3 will vote
    u1 = User.find(1)
    u2 = User.find(3)
    u3 = User.find(56)
    [u1, u2].each do |u|
      [1, 2].each do |comment_id|
        u.comments_valorations.create(
            :comment_id => comment_id,
            :comments_valorations_type_id => 1,
            :weight => 0.3)
      end
    end

    u3.comments_valorations.create(
        :comment_id => 1, :comments_valorations_type_id => 1, :weight => 0.3)

    assert !u3.has_emblem?("comments_valorations_#{level}")
    assert_difference("u3.comments_valorations.count") do
      self.override_threshold("T_COMMENT_VALORATIONS_#{level}", 2) do
        self.override_threshold(
            "T_COMMENT_VALORATIONS_#{level}_MATCHING_USERS", 2) do
          u3.comments_valorations.create(
              :comment_id => 2,
              :comments_valorations_type_id => 1,
              :weight => 0.3)
        end
      end
    end
    u3.reload
    assert u3.has_emblem?("comments_valorations_#{level}")
  end

  test "user_referers nothing" do
    assert_difference("UsersEmblem.count", 0) do
      UserEmblemObserver::Emblems.check_user_referers_candidates
    end
  end

  test "user_referers 1" do
    self.ensure_user_referer(1)
  end

  test "user_referers 2" do
    self.ensure_user_referer(2)
  end

  test "user_referers 3" do
    self.ensure_user_referer(3)
  end

  def ensure_user_referer(level)
    u2 = User.find(2)
    u2.update_attributes({
        :comments_count => 1,
        :created_on => 1.year.ago,
        :lastseen_on => 1.day.ago,
        :referer_user_id => 1,
    })
    u1 = User.find(1)

    self.override_threshold("T_REFERER_#{level}", 1) do
      assert_difference(
          "u1.users_emblems.emblem('user_referer_#{level}').count") do
        UserEmblemObserver::Emblems.check_user_referers_candidates
      end
    end
  end
end
