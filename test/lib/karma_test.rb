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
    # La primera instancia no tiene los datos frescos, ok, para eso usamos la
    # cache.
    assert_equal kp_initial + 1, u_a.karma_points
    assert_equal kp_initial + 2, u_b.karma_points
    u_a.reload
    u_b.reload
    assert_equal kp_initial + 2, u_a.karma_points
    assert_equal kp_initial + 2, u_b.karma_points
  end

  test "award_karma_points_new_ugc" do
    Karma.award_karma_points_new_ugc
  end

  test "update_ranking" do
    User.db_query("UPDATE users SET cache_karma_points = id")
    Karma.update_ranking
    users_count = User.can_login.count
    assert_equal users_count, User.find(1).ranking_karma_pos
    assert_equal users_count - 1, User.find(2).ranking_karma_pos
    assert_equal users_count - 2, User.find(3).ranking_karma_pos
  end

  test "calculate_new_comments_karma_points shouldn't touch unpublished contents" do
    content = Content.find(1)
    assert content.update_attributes(:karma_points => nil)

    [Cms::DELETED].each do |state|
      content.real_content.change_state(state, Ias.MrMan)
      Karma.award_karma_points_new_ugc
      content.reload
      assert content.karma_points.nil?
    end
  end

  test "calculate_new_contents_karma_points shouldn't touch published but too recent" do
  end

  test "calculate_new_contents_karma_points should give karma for old enough" do
  end

  test "calculate_new_contents_karma_points shouldn't give karma twice for the same content" do
  end

  test "calculate_new_contents_karma_points should give karma appropriately" do
  end

  test "calculate_new_comments_karma_points shouldn't touch unpublished comments" do
    comment = Comment.find(1)
    assert comment.update_column(:karma_points, nil)

    [Comment::DUPLICATED, Comment::MODERATED].each do |state|
      comment.state = state
      assert comment.save
      assert_nil comment.karma_points
    end
  end

  test "calculate_new_comments_karma_points shouldn't touch published but too recent" do
    User.db_query(
        "UPDATE comments
         SET created_on = NOW(),
           karma_points = NULL
         WHERE id = 1")
    comment = Comment.find(1)
    comment.reload
    assert_nil comment.karma_points
  end

  test "calculate_new_comments_karma_points should give karma for old enough" do
    User.db_query(
        "UPDATE comments
         SET created_on = NOW() - '#{Karma::UGC_OLD_ENOUGH_FOR_KARMA_DAYS + 1} days'::interval,
           karma_points = NULL
         WHERE id = 1")
    comment = Comment.find(1)
    assert_difference("comment.comments_valorations.count") do
      comment.comments_valorations.create({
        :user_id => 3,
        :comments_valorations_type_id => CommentsValorationsType.positive.find(:first).id,
        :weight => 0.5,
      })
    end
    Karma.award_karma_points_new_ugc
    comment.reload
    assert_not_nil comment.karma_points
  end

  test "calculate_new_comments_karma_points shouldn't touch karma once its given" do
    User.db_query(
        "UPDATE comments
         SET created_on = NOW() - '#{Karma::UGC_OLD_ENOUGH_FOR_KARMA_DAYS + 1} days'::interval,
           karma_points = 3
         WHERE id = 1")
    comment = Comment.find(1)
    Karma.award_karma_points_new_ugc
    comment.reload
    # If award_karma_points_new_ugc would change it should reset its
    # karma_points to 0 because the comment has no valorations.
    assert_equal 3, comment.karma_points
  end

  test "calculate_new_comments_karma_points should give karma appropriately" do
  end

end
