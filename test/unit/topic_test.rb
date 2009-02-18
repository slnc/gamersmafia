require File.dirname(__FILE__) + '/../test_helper'

class TopicTest < Test::Unit::TestCase
  def setup
    @forum_topic = Topic.find(1)
  end
  
  # Replace this with your real tests.
  def test_should_update_parent_categories_counter
    @cat1 = TopicsCategory.new({:name => 'catfather', :code => 'c1'})
    assert_equal true, @cat1.save
    @subcat1 = @cat1.children.create({:name => 'catsubfather', :code => 'c2'})
    assert_equal true, @subcat1.save
    @topic = Topic.new({:user_id => 1, :topics_category_id => @subcat1.id, :title => 'topic 1', :main => 'topic1'})
    assert_equal true, @topic.save, @topic.errors
    @cat1.reload
    @subcat1.reload
    assert_equal 1, @cat1.topics_count
    assert_equal 1, @subcat1.topics_count
  end
  
  def test_should_update_parent_categories_counter_after_marking_as_deleted_topic
    test_should_update_parent_categories_counter  
    t = Topic.find(:first, :order => 'id DESC')
    Cms::modify_content_state(t, User.find(1), Cms::DELETED)
    t.reload
    assert t.state == Cms::DELETED
    @cat1.reload
    @subcat1.reload
    assert_equal 0, @cat1.topics_count
    assert_equal 0, @subcat1.topics_count
  end
  
  def test_should_update_parent_categories_counter_after_moving_to_new_category
    test_should_update_parent_categories_counter
    t = Topic.find(:first, :order => 'id DESC')
    @cat2 = TopicsCategory.new({:name => 'catfather2', :code => 'c2'})
    assert_equal true, @cat2.save
    @subcat2 = @cat2.children.create({:name => 'catsubfather2', :code => 'sc2'})
    assert_equal true, @subcat2.save
    t.topics_category_id = @subcat2.id
    t.save
    @cat1.reload
    @subcat1.reload
    @cat2.reload
    @subcat2.reload
    assert_equal 0, @cat1.topics_count
    assert_equal 0, @subcat1.topics_count
    assert_equal 1, @cat2.topics_count
    assert_equal 1, @subcat2.topics_count
  end
  
  def test_should_update_categories_comments_count_after_commenting
    test_should_update_parent_categories_counter
    @t = Topic.find(:first, :order => 'id DESC')
    @comment = Comment.new({:content_id => @t.unique_content.id, 
      :user_id => 1, 
      :host => '0.0.0.0', 
      :comment => 'holitas vecinito'})
    assert_equal true, @comment.save
    @t.reload
    assert_equal 1, @t.cache_comments_count
    @cat1.reload
    @subcat1.reload
    assert_equal 1, @cat1.comments_count
    assert_equal 1, @subcat1.comments_count
  end
  
  def test_should_update_categories_comments_count_after_deleting_commenting
    test_should_update_categories_comments_count_after_commenting
    init_ccount = @subcat1.comments_count
    
    @comment.mark_as_deleted
    @t.reload
    assert_equal 0, @t.cache_comments_count
    @cat1.reload
    @subcat1.reload
    # puts "cat.id #{@cat1.id} | subcat1.id #{@subcat1.id}"
    assert_equal 0, @cat1.comments_count
    assert_equal 1, @subcat1.comments_count, @subcat1.comments_count
  end
  
  # TODO al mover contenidos no se actualizan los contadores de comentarios totales en categoría
end
