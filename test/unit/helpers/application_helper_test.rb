require File.dirname(__FILE__) + '/../../test_helper'

class ApplicationHelperTest < HelperTestCase

  include ApplicationHelper

  def setup
    super
  end
  
  def test_faction_favicon_should_show_bla
    assert_not_nil faction_favicon(Faction.find(:first))
  end
end
