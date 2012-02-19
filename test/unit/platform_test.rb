require 'test_helper'

class PlatformTest < ActiveSupport::TestCase
  test "create_term" do
    @platform = Platform.new(:name => 'foo', :code => 'bar')
    assert @platform.save
    t = Term.find(
        :first,
        :conditions => ['platform_id = ? AND parent_id IS NULL', @platform.id])
    assert t
    assert_equal @platform.name, t.name
    assert_equal @platform.code, t.slug
  end

  test "should_create_if_everything_ok" do
    self.create_platform
    assert_not_nil Platform.find_by_name('Worms')
    assert_not_nil Platform.find_by_code('w')
  end

  test "should_create_contents_categories_if_everything_ok" do
    self.create_platform
    root_term = Term.single_toplevel(:platform_id => @platform.id)
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
    @platform = Platform.new({:name => 'Worms', :code => 'w'})
    assert @platform.save, @platform.errors.full_messages_html
  end
end
