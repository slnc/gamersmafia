require 'test_helper'

class PortalTest < ActiveSupport::TestCase

  test "should_work_if_good_data" do
    portal = Portal.new(:code => "#{Portal::UNALLOWED_CODES[0]}00", :name => 'Fulanito de tal')
    assert portal.save, portal.errors.full_messages_html
  end
  
  test "shouldnt_allow_to_save_with_restricted_portal_code" do
    portal = Portal.new(:code => Portal::UNALLOWED_CODES[0], :name => 'Fulanito de tal')
    assert !portal.save
  end
end
