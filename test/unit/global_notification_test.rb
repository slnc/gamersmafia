require File.dirname(__FILE__) + '/../test_helper'

class GlobalNotificationTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_no_flood
    gn = GlobalNotification.new(:title => "foo", :main => "bar", :recipient_type => GlobalNotification::VALID_RECIPIENT_TYPES.first)
    assert gn.save
    gn.confirmed = true
    assert gn.save
    
    gn2 = GlobalNotification.new(:title => "foo2", :main => "bar2", :recipient_type => gn.recipient_type)
    assert gn2.save
    gn2.confirmed = true
    assert !gn2.save
    
    assert GlobalNotification::VALID_RECIPIENT_TYPES.first != GlobalNotification::VALID_RECIPIENT_TYPES.last
    gn3 = GlobalNotification.new(:title => "foo3", :main => "bar3", :recipient_type => GlobalNotification::VALID_RECIPIENT_TYPES.last)
    
     
    assert gn3.save
    gn3.confirmed = true
    assert gn3.save
  end
end
