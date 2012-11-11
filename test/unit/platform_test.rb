# -*- encoding : utf-8 -*-
require 'test_helper'

class GamingPlatformTest < ActiveSupport::TestCase
  test "create_term" do
    @platform = GamingPlatform.new(:name => 'foo', :slug => 'bar')
    assert @platform.save
    @platform.create_contents_categories
    t = Term.find(
        :first,
        :conditions => ['gaming_platform_id = ? AND parent_id IS NULL', @platform.id])
    assert t
    assert_equal @platform.name, t.name
    assert_equal @platform.slug, t.slug
  end

  test "should_create_if_everything_ok" do
    self.create_platform
    assert_not_nil GamingPlatform.find_by_name('Worms')
    assert_not_nil GamingPlatform.find_by_slug('w')
  end

  test "should_create_contents_categories_if_everything_ok" do
    self.create_platform
    @platform.create_contents_categories
    root_term = Term.single_toplevel(:gaming_platform_id => @platform.id)
    assert_not_nil root_term
    Organizations::DEFAULT_CONTENTS_CATEGORIES.each do |c|
      assert_not_nil(root_term.children.find(
          :first, :conditions => ['taxonomy = ? AND name = ?', c[0], c[1]]),
          "Couldn't find a child of #{root_term} with taxonomy=#{c[0]} and" +
          " name #{c[1]}")
    end
  end

  protected
  def create_platform
    @platform = GamingPlatform.new({:name => 'Worms', :slug => 'w'})
    assert @platform.save, @platform.errors.full_messages_html
  end
end
