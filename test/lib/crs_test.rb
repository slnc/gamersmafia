# -*- encoding : utf-8 -*-
require 'test_helper'

class CrsTest < ActiveSupport::TestCase
  test "recommend_from_contents_term should work" do
    u1 = User.find(4)
    term = Term.create(:name => "aguacate", :taxonomy => "ContentsTag")
    u1.user_interests.create(
        :entity_type_class => "Term", :entity_id => term.id)
    c1 = Content.find(1)
    assert_difference("u1.contents_recommendations.count") do
      term.link(c1)
    end
  end
end
