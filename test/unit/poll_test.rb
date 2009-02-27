require File.dirname(__FILE__) + '/../test_helper'

class PollTest < Test::Unit::TestCase

  def setup
    @poll = Poll.find(1)
  end

  def test_should_not_allow_to_create_poll_with_end_date_sooner_than_start_date
    poll = Poll.new({:terms => 1, :user_id => 1, :state => Cms::PENDING, :title => 'olaaaaaaaa', :starts_on => 7.day.since, :ends_on => 1.day.since})
    assert_equal false, poll.save
  end

  def test_should_not_allow_to_create_poll_with_starts_on_sooner_than_now
    poll = Poll.new({:terms => 1, :user_id => 1, :state => Cms::PENDING, :title => 'olaaaaaaaa', :starts_on => 1.day.ago, :ends_on => 1.day.since})
    assert_equal false, poll.save
  end

  def test_should_allow_to_create_poll_if_everything_ok
    poll = Poll.new({:terms => 1, :user_id => 1, :state => Cms::PENDING, :title => 'olaaaaaaaa', :starts_on => 1.day.since, :ends_on => 7.day.since})
    assert_equal true, poll.save
  end

  def test_should_properly_set_solapping_poll
    p1 = Poll.find(1)
    pn = Poll.new({:polls_category_id => p1.polls_category_id, :title => "holitas carambolitas", :user_id => 1, :starts_on => p1.starts_on, :ends_on => p1.ends_on})
    assert_equal true, pn.save, pn.errors.full_messages_html
    assert_equal Time.at(p1.ends_on.to_i + 1), pn.starts_on
    assert_equal pn.starts_on.advance({:days => 7}), pn.ends_on
  end
  
  def test_shouldnt_touch_non_solapping_poll
    p1 = Poll.find(1)
    pn = Poll.new({:polls_category_id => p1.polls_category_id, :title => "holitas carambolitas", :user_id => 1, :starts_on => p1.ends_on.advance({:days => 1}), :ends_on => p1.ends_on.advance({:days => 9})})
    assert_equal true, pn.save, pn.errors.full_messages_html
    assert_equal p1.ends_on.advance({:days => 1}), pn.starts_on
    assert_equal p1.ends_on.advance({:days => 9}), pn.ends_on
  end
end
