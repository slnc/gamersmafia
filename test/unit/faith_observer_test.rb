require File.dirname(__FILE__) + '/../test_helper'

class FaithObserverTest < Test::Unit::TestCase
  
  def test_should_give_faith_after_creating_content_rating
    initial_cr = ContentRating.count
    @u1 = User.find(1)
    @initial_fp = @u1.faith_points
    @cr = @u1.content_ratings.create({:ip => '0.0.0.0', :content_id => Content.find(:first, :conditions => 'id NOT IN (SELECT content_id from content_ratings where user_id = 1)').id, :rating => 1})
    assert_equal initial_cr + 1, ContentRating.count
    @u1.reload
    assert_equal @initial_fp + Faith::FPS_ACTIONS['rating'], @u1.faith_points
  end
  
  def test_should_take_faith_after_destroying_content_rating
    test_should_give_faith_after_creating_content_rating
    @initial_fp = @u1.faith_points
    @cr.destroy
    @u1.reload
    assert_equal @initial_fp - Faith::FPS_ACTIONS['rating'], @u1.faith_points
  end
    
    # TODO
#  def test_should_give_faith_after_creating_comment_rating
#    initial_cr = CommentsValoration.count
#    @u1 = User.find(1)
#    @initial_fp = @u1.faith_points
#    @cr = @u1.comments_valorations.create({:comments_valorations_type_id => 1, :comment_id => Comment.find(:first, :conditions => 'user_id <> 1').id, :rating => 1})
#    assert_equal initial_cr + 1, ContentRating.count
#    @u1.reload
#    assert_equal @initial_fp + Faith::FPS_ACTIONS['rating'], @u1.faith_points
#  end
#  
#  def test_should_take_faith_after_destroying_comment_rating
#    test_should_give_faith_after_creating_content_rating
#    @initial_fp = @u1.faith_points
#    @cr.destroy
#    @u1.reload
#    assert_equal @initial_fp - Faith::FPS_ACTIONS['rating'], @u1.faith_points
#  end
  
  def test_should_take_faith_after_destroying_user_with_referer_user_id
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
  
  def test_should_take_faith_after_destroying_user_with_resurrected_by_user_id_not_own
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
  
  def test_should_take_faith_after_destroying_user_with_resurrected_by_user_id_own
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
  
  def test_should_take_faith_after_destroying_user_with_resurrected_by_user_id_and_refered_by_other
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
  
  def test_should_reset_faith_after_saving_publishing_decision
    @u1 = User.find(1)
    @u1.faith_points
    assert_count_increases(PublishingDecision) do
      PublishingDecision.create({:user_id => 1, :content_id => 1, :publish => true, :user_weight => 0.5})
    end
    @u1.reload
    assert_nil @u1.cache_faith_points
  end
end