require 'test_helper'

class ApplicationHelperTest < HelperTestCase

  include ApplicationHelper

  def setup
    super
  end
  
  test "faction_favicon_should_show_bla" do
    assert_not_nil faction_favicon(Faction.find(:first))
  end
end
