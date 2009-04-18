require 'test_helper'

class GmPortalTest < ActiveSupport::TestCase

  test "has_name" do
    assert_not_nil GmPortal.new.name
  end

  test "should_respond_to_all_content_classes" do
    p = GmPortal.new
    Cms::contents_classes_symbols.each do |s|
      assert_not_nil p.send(s)
    end
  end
  
end
