require File.dirname(__FILE__) + '/../test_helper'

class PortalTest < Test::Unit::TestCase

  def test_should_work_if_good_data
    portal = Portal.new(:code => "#{Portal::UNALLOWED_CODES[0]}00", :name => 'Fulanito de tal')
    assert portal.save, portal.errors.full_messages_html
  end
  
  def test_shouldnt_allow_to_save_with_restricted_portal_code
    portal = Portal.new(:code => Portal::UNALLOWED_CODES[0], :name => 'Fulanito de tal')
    assert !portal.save
  end
end
