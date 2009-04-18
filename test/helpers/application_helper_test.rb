require 'test_helper'

class ApplicationHelperTest < HelperTestCase
  include ApplicationHelper
  
  test "smilelize" do
    assert_equal '<p>foo</p>', smilelize('foo')
    assert_equal '<p><img src="/images/smileys/666.gif" /></p>', smilelize(':666:')
    assert_equal '<p>hola <img src="/images/smileys/666.gif" /></p>', smilelize('hola :666:')
  end
end