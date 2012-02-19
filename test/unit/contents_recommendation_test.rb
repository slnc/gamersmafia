require 'test_helper'

class ContentsRecommendationTest < ActiveSupport::TestCase

  test "cannot_recommend_to_self" do
    # flunk
  end

  test "cannot_recommend_if_user_already_saw_content" do

  end

  test "if you get a recommendation from a seen content automatically mark the new recommendation as seen" do
    u1 = User.find(1)
    u2 = User.find(2)
    u3 = User.find(3)
    c1 = Content.find(1)
    cr1 = ContentsRecommendation.new(:sender_user_id => 2, :receiver_user_id => 1, :content_id => 1)
    assert cr1.save
    cr1.mark_seen
    cr2 = ContentsRecommendation.new(:sender_user_id => 3, :receiver_user_id => 1, :content_id => 1)
    assert cr2.save
    assert cr2.created_on >= cr2.seen_on
  end

  test "mark all recommendations as seen when they belong to the same content" do
    u1 = User.find(1)
    u2 = User.find(2)
    u3 = User.find(3)
    c1 = Content.find(1)
    cr1 = ContentsRecommendation.new(:sender_user_id => 2, :receiver_user_id => 1, :content_id => 1)
    assert cr1.save
    cr2 = ContentsRecommendation.new(:sender_user_id => 3, :receiver_user_id => 1, :content_id => 1)
    assert cr2.save
    cr1.mark_seen
    cr2.reload
    assert_equal cr2.created_on, cr2.seen_on
  end
end
