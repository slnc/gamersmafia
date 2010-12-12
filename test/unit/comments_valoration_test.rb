require 'test_helper'

class CommentsValorationTest < ActiveSupport::TestCase
  test "should reset caches after creation" do
    c = Comment.find(1)
    u = c.user
    u.valorations_weights_on_self_comments
    assert_count_increases(CommentsValoration) do
      CommentsValoration.create(:comment_id => c.id, :comments_valorations_type_id => 2, 
                                :user_id => 3, :weight => 3)
    end
    u.reload
    assert_nil u.cache_valorations_weights_on_self_comments
  end
end
