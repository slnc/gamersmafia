require File.dirname(__FILE__) + '/../test_helper'

class PlatformTest < Test::Unit::TestCase
  def test_create_term
    @platform = Platform.new(:name => 'foo', :code => 'bar')
    assert @platform.save 
    t = Term.find(:first, :conditions => ['platform_id = ? AND parent_id IS NULL', @platform.id])
    assert t
    assert_equal @platform.name, t.name
    assert_equal @platform.code, t.slug
  end
end
