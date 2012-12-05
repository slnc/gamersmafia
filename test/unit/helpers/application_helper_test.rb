# -*- encoding : utf-8 -*-
require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase

  test "initial_sentences1" do
    assert_equal "hello ...", initial_sentences("hello world foo", 5)
    assert_equal "hello ...", initial_sentences("hello world foo", 6)
    assert_equal "hello world ...", initial_sentences("hello world foo", 12)
    assert_equal "hello world", initial_sentences("<p>hello\nworld</p> foo", 12)
  end

  test "smilelize" do
    assert_equal '<p>foo</p>', smilelize('foo')
    assert_equal '<p><img src="/images/smileys/666.gif" /></p>', smilelize(':666:')
    assert_equal '<p>hola <img src="/images/smileys/666.gif" /></p>', smilelize('hola :666:')
  end

  test "faction_favicon_should_show_work" do
    assert_not_nil faction_favicon(Faction.find(:first))
  end

  test "should_show_bottom_ad for anonymous" do
    self.controller.expects(:user_is_authed).returns(false)
    self.controller.expects(:no_ads).returns(false)
    assert should_show_bottom_ad?
  end

  test "should_show_bottom_ad for registered young member" do
    self.expects(:user_is_authed).returns(true)
    self.controller.expects(:no_ads).returns(false)
    @user = User.first
    @user.created_on = 1.day.ago
    assert should_show_bottom_ad?
  end
end
