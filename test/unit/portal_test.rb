# -*- encoding : utf-8 -*-
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

  test "should update global vars after save" do
    User.db_query("UPDATE global_vars SET portals_updated_on = now() - '1 day'::interval")
    test_should_work_if_good_data
    assert User.db_query("SELECT portals_updated_on FROM global_vars")[0]['portals_updated_on'].to_time > 1.minute.ago
  end

end
