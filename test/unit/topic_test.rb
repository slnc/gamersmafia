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
    topics1.link(t1.unique_content)
    topics2.link(t2.unique_content)
    last_topics = Topic.latest_by_category
    assert last_topics.include?(t2.id)
    assert !last_topics.include?(t1.id)
  end
end
