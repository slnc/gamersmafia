# -*- encoding : utf-8 -*-
require 'test_helper'

class TagsHelperTest < ActionView::TestCase
  test "top_tags_by_interest" do
    t1 = Term.with_taxonomy("ContentsTag").first
    u1 = User.find(1)
    u1.user_interests.create(:entity_type_class => "Term", :entity_id => t1.id)
    top_tags_by_interest
  end
end
