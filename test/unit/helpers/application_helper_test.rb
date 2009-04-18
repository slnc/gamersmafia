require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "faction_favicon_should_show_work" do
    # TODO incompleto
    assert_not_nil faction_favicon(Faction.find(:first))
  end

  test "smilelize" do
    assert_equal '<p>foo</p>', smilelize('foo')
    assert_equal '<p><img src="/images/smileys/666.gif" /></p>', smilelize(':666:')
    assert_equal '<p>hola <img src="/images/smileys/666.gif" /></p>', smilelize('hola :666:')
  end
end
