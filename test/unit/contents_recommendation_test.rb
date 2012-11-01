# -*- encoding : utf-8 -*-
require 'test_helper'

class ContentsRecommendationTest < ActiveSupport::TestCase

  test "cannot_recommend_to_self" do
    # flunk
  end

  test "cannot_recommend_if_user_already_saw_content" do
    u1 = User.find(2)
    content1 = Content.find(1)
    tracker_item = TrackerItem.create(
        :user_id => u1.id, :content_id => content1.id, :lastseen_on => Time.now)
    cr1 = ContentsRecommendation.new({
        :content_id => content1.id,
        :receiver_user_id => u1.id,
        :sender_user_id => 4,
    })
    assert !cr1.save
  end

  test "don't allow duplicated recommendations" do
    u1 = User.find(4)
    u2 = User.find(2)
    u3 = User.find(3)
    c1 = Content.find(1)
    cr1 = ContentsRecommendation.new(
        :sender_user_id => 2, :receiver_user_id => u1.id, :content_id => 1)
    assert cr1.save
    cr1.mark_seen
    cr2 = ContentsRecommendation.new(
        :sender_user_id => 3, :receiver_user_id => u1.id, :content_id => 1)
    assert !cr2.save
  end

  test "mark recommendation as seen" do
    u1 = User.find(4)
    u2 = User.find(2)
    u3 = User.find(3)
    c1 = Content.find(1)
    cr1 = ContentsRecommendation.new(
        :sender_user_id => 2, :receiver_user_id => u1.id, :content_id => 1)
    assert cr1.save
    cr1.mark_seen
    assert !cr1.seen_on.nil?
  end
end
