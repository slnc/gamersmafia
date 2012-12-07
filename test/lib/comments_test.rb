# -*- encoding : utf-8 -*-
require 'test_helper'

class CommentsTest < ActiveSupport::TestCase
  test "sicario_cannot_edit_comments_of_own_district" do
    u59 = User.find(59)
    bd = BazarDistrict.find(1)
    bd.add_sicario(u59)
    n65 = News.find(65)
    c = Comment.new(
        :content_id => n65.id,
        :user_id => 1,
        :host => '127.0.0.1',
        :comment => 'comentario')
    assert c.save
    assert !c.can_edit_comment?(u59)
  end
end
