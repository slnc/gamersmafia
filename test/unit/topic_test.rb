# -*- encoding : utf-8 -*-
require 'test_helper'

class TopicTest < ActiveSupport::TestCase
  def setup
    @forum_topic = Topic.find(1)
  end

  test "latest_by_category" do
    rt = Term.single_toplevel(:slug => 'ut')
    topics1 = rt.children.create(:name => 'topics1', :taxonomy => 'TopicsCategory')
    topics2 = rt.children.create(:name => 'topics2', :taxonomy => 'TopicsCategory')
    t1 = Topic.create(:title => 'topiquito1', :user_id => 1, :main => 'foo bar chaz')
    t2 = Topic.create(:title => 'topiquito2', :user_id => 1, :main => 'foo bar chaz a')
    topics1.link(t1)
    topics2.link(t2)

    gm = Term.single_toplevel(:slug => 'gm')
    gmtopics1 = gm.children.create(:name => 'topics1', :taxonomy => 'TopicsCategory')
    gmtopics2 = gm.children.create(:name => 'topics2', :taxonomy => 'TopicsCategory')
    gmt1 = Topic.create(:title => 'topiquito1', :user_id => 1, :main => 'foo bar chaz')
    gmt2 = Topic.create(:title => 'topiquito2', :user_id => 1, :main => 'foo bar chaz a')
    gmtopics1.link(gmt1)
    gmtopics2.link(gmt2)

    rt.reload
    gm.reload

    last_topics = Topic.latest_by_category

    assert_equal last_topics[0], gmt2
    assert !last_topics.include?(gmt1)

    assert_equal last_topics[1], t2
    assert !last_topics.include?(t1)
  end
end
