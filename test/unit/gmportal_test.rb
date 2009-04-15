require File.dirname(__FILE__) + '/../test_helper'

class GmPortalTest < ActiveSupport::TestCase

  def test_has_name
    assert_not_nil GmPortal.new.name
  end

  def test_should_respond_to_all_content_classes
    p = GmPortal.new
    Cms::contents_classes_symbols.each do |s|
      assert_not_nil p.send(s)
    end
  end
  
end
