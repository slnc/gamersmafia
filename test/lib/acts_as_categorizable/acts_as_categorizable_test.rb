require File.dirname(__FILE__) + '/../../../test/test_helper'
require 'RMagick'

class ActsAsCategorizableTest < ActiveSupport::TestCase
  def setup
    ActiveRecord::Base.db_query('CREATE TABLE acts_as_categorizable_test_classes(id serial primary key not null unique, name varchar)')
  end

  test "affected_classes_should_respond_to_acts_as_categorizable" do
    #klass = Class.new(ActiveRecord::Base) do
    #  acts_as_categorizable
    #end

    #Object.const_set("ActsAsCategorizableTest", klass)

    assert_equal true, ActsAsCategorizableTestClass.respond_to?(:is_categorizable?)
    assert_equal true, ActsAsCategorizableTestClass.new.respond_to?(:is_categorizable?)
  end

  test "non_affected_classes_should_not_respond_to_acts_as_categorizable" do
    assert_equal false, ActiveRecord::Base.respond_to?(:acts_as_categorizable?)
  end

  def atest_should_properly_update_last_commented_item_in_a_category_when_the_last_commented_item_is_moved_to_another_category_and_the_category_has_no_more_items
    @t1cat = TopicsCategory.create({:name => 'toplevel1'})
    @t1child = @t1cat.children.create({:name => 'firstchild1'})
    @t2cat = TopicsCategory.create({:name => 'toplevel2'})
    @t2child = @t2cat.children.create({:name => 'firstchild2'})
    t1 = Topic.create({:topics_category_id => @t1child.id, :title => 'fooo topic in test', :main => 'abracadabra', :user_id => 1, :state => Cms::PUBLISHED, :user_id => 1})
    assert_not_nil t1
    c = Comment.new({:user_id => 1, :comment => 'hola mundo!', :content_id => t1.unique_content.id, :host => '127.0.0.1'})
    assert_equal true, c.save
    t1.topics_category_id = @t2child.id
    t1.save
    [@t1cat, @t1child, @t2cat, @t2child].each { |thing| thing.reload }
    assert_nil @t1cat.last_updated_item_id, @t1cat.id.to_s
    assert_nil @t1child.last_updated_item_id
    assert_equal t1.id, @t2cat.last_updated_item_id
    assert_equal t1.id, @t2child.last_updated_item_id
  end

  test "should_properly_update_last_commented_item_in_a_category_when_the_last_commented_item_is_moved_to_another_category_and_the_category_has_more_items" do
  end

  def teardown
    ActiveRecord::Base.db_query('DROP TABLE acts_as_categorizable_test_classes')
  end
end

class ActsAsCategorizableTestClass < ActiveRecord::Base
  acts_as_categorizable
end
