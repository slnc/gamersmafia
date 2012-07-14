require 'test_helper'

class FaithObserverTest < ActiveSupport::TestCase

  test "should_give_faith_after_creating_users_contents_tag" do
    initial_cr = UsersContentsTag.count
    @content = Content.find(1)
    @u1 = User.find(1)
    @initial_fp = @u1.faith_points

    UsersContentsTag.tag_content(@content, @u1, 'hola mundo', delete_missing=false)

    assert_equal initial_cr + 2, UsersContentsTag.count
    @u1.reload
    assert_equal @initial_fp + Faith::FPS_ACTIONS['users_contents_tag']*2, @u1.faith_points
  end

  test "should_take_faith_after_destroying_users_contents_tag" do
    test_should_give_faith_after_creating_users_contents_tag
    @initial_fp = @u1.faith_points
    UsersContentsTag.tag_content(@content, @u1, '', delete_missing=true)
    @u1.reload
    assert_equal @initial_fp - Faith::FPS_ACTIONS['users_contents_tag']*2, @u1.faith_points
  end

  test "should_give_faith_after_creating_content_rating" do
    initial_cr = ContentRating.count
    @u1 = User.find(1)
    content = Content.find(
        :first,
        :conditions => ["user_id <> ?", 1])
    content.content_ratings.clear
    @initial_fp = @u1.faith_points
    assert_difference("ContentRating.count") do
      @cr = @u1.content_ratings.create({
          :ip => '0.0.0.0',
          :content_id => content.id,
          :rating => 1
      })
    end
    @u1.reload
    assert_equal @initial_fp + Faith::FPS_ACTIONS['rating'], @u1.faith_points
  end

  test "should_take_faith_after_destroying_content_rating" do
    test_should_give_faith_after_creating_content_rating
    @initial_fp = @u1.faith_points
    @cr.destroy
    @u1.reload
    assert_equal @initial_fp - Faith::FPS_ACTIONS['rating'], @u1.faith_points
  end

  test "should_give_faith_after_creating_comment_rating" do
    initial_cr = CommentsValoration.count
    @u1 = User.find(1)
    @initial_fp = @u1.faith_points
    assert_difference("CommentsValoration.count") do
      @cr = @u1.comments_valorations.create({
          :comments_valorations_type_id => 1,
          :comment_id => Comment.find(:first, :conditions => 'user_id <> 1').id,
          :weight => 0.1,
      })
    end
    assert_not_equal @cr.new_record?, @cr.errors.full_messages_html
    @u1.reload
    assert_equal @initial_fp + Faith::FPS_ACTIONS['rating'], @u1.faith_points
  end

  test "should_take_faith_after_destroying_comment_rating" do
    test_should_give_faith_after_creating_content_rating
    @initial_fp = @u1.faith_points
    @cr.destroy
    @u1.reload
    assert_equal @initial_fp - Faith::FPS_ACTIONS['rating'], @u1.faith_points
  end

  test "should_take_faith_after_destroying_user_with_referer_user_id" do
    User.db_query("UPDATE users SET referer_user_id = 1 WHERE id = 3")
    @u1 = User.find(1)
    @u3 = User.find(3)
    @u1.cache_faith_points = nil
    @u1.save
    initial_fp = @u1.faith_points
    assert_equal @u1.id, @u3.referer.id
    @u3.destroy
    assert_equal true, @u3.frozen?
    @u1.reload
    assert_equal initial_fp - Faith::FPS_ACTIONS['registration'], @u1.faith_points
  end

  test "should_take_faith_after_destroying_user_with_resurrected_by_user_id_not_own" do
    User.db_query("UPDATE users SET resurrected_by_user_id = 1 WHERE id = 3")
    @u1 = User.find(1)
    @u3 = User.find(3)
    @u1.cache_faith_points = nil
    @u1.save
    initial_fp = @u1.faith_points
    assert_equal @u1.id, @u3.resurrector.id
    @u3.destroy
    assert_equal true, @u3.frozen?
    @u1.reload
    assert_equal initial_fp - Faith::FPS_ACTIONS['resurrection'], @u1.faith_points
  end

  test "should_take_faith_after_destroying_user_with_resurrected_by_user_id_own" do
    User.db_query("UPDATE users SET resurrected_by_user_id = 1, referer_user_id = 1 WHERE id = 3")
    @u1 = User.find(1)
    @u3 = User.find(3)
    @u1.cache_faith_points = nil
    @u1.save
    initial_fp = @u1.faith_points
    assert_equal @u1.id, @u3.resurrector.id
    @u3.destroy
    assert_equal true, @u3.frozen?
    @u1.reload
    assert_equal initial_fp - Faith::FPS_ACTIONS['resurrection_own'] - Faith::FPS_ACTIONS['registration'], @u1.faith_points
  end

  test "should_take_faith_after_destroying_user_with_resurrected_by_user_id_and_refered_by_other" do
    User.db_query("UPDATE users SET resurrected_by_user_id = 1, referer_user_id = 2 WHERE id = 3")
    @u1 = User.find(1)
    @u2 = User.find(2)
    @u3 = User.find(3)
    @u1.cache_faith_points = nil
    @u1.save
    @u2.cache_faith_points = nil
    @u2.save
    initial_fp_u1 = @u1.faith_points
    initial_fp_u2 = @u2.faith_points
    assert_equal @u1.id, @u3.resurrector.id
    assert_equal @u2.id, @u3.referer.id
    @u3.destroy
    assert_equal true, @u3.frozen?
    @u1.reload
    @u2.reload
    assert_equal initial_fp_u1 - Faith::FPS_ACTIONS['resurrection'], @u1.faith_points
    assert_equal initial_fp_u2 - Faith::FPS_ACTIONS['registration'], @u2.faith_points
  end

  test "should_reset_faith_after_saving_publishing_decision" do
    @u1 = User.find(1)
    @u1.faith_points
    assert_count_increases(PublishingDecision) do
      PublishingDecision.create({:user_id => 1, :content_id => 1, :publish => true, :user_weight => 0.5})
    end
    @u1.reload
    assert_nil @u1.cache_faith_points
  end
end
