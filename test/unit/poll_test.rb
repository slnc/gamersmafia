# -*- encoding : utf-8 -*-
require 'test_helper'

class PollTest < ActiveSupport::TestCase

  def setup
    @poll1 = Poll.published.first
  end

  test "should_not_allow_to_create_poll_with_end_date_sooner_than_start_date" do
    poll = self.new_poll_with({
      :ends_on => 1.day.since,
      :starts_on => 7.day.since,
    })
    assert !poll.save
  end

  test "should_not_allow_to_create_poll_with_starts_on_sooner_than_now" do
    poll = self.new_poll_with({
        :ends_on => 1.day.since,
        :starts_on => 1.day.ago,
    })
    assert !poll.save
  end

  test "should_allow_to_create_poll_if_everything_ok" do
    poll = self.new_poll_with({
      :ends_on => 7.day.since,
      :starts_on => 1.day.since,
    })
    assert_equal true, poll.save
    assert_equal 2, poll.polls_options.count
    assert_not_nil poll.polls_options.find_by_name('opcion1')
    assert_not_nil poll.polls_options.find_by_name('opcion2')
  end

  test "should_properly_update" do
    poll = self.new_poll_with({
      :ends_on => 7.day.since,
      :starts_on => 1.day.since,
    })
    assert_equal true, poll.save

    poll.update_attributes(:options_new => 'opcion3')
    assert_equal 3, poll.polls_options.count
    assert_not_nil poll.polls_options.find_by_name('opcion3')

    poll.update_attributes({
      :options_delete => [poll.polls_options.find_by_name('opcion3').id]
    })
    assert_equal(2, poll.polls_options.count)
    assert_nil(poll.polls_options.find_by_name('opcion3'))

    poll.update_attributes({
      :options => {poll.polls_options.find_by_name('opcion1').id => 'fulanito'}
    })
    assert_equal 2, poll.polls_options.count
    assert_not_nil poll.polls_options.find_by_name('fulanito')
    assert_nil poll.polls_options.find_by_name('opcion1')
  end

  test "should_properly_set_solapping_poll" do
    poll = self.new_poll_with({
        :terms => @poll1.terms[0].id,
        :starts_on => @poll1.starts_on,
        :ends_on => @poll1.ends_on,
    })

    assert(poll.save, poll.errors.full_messages_html)
    assert_equal(Time.at(@poll1.ends_on.to_i + 1), poll.starts_on)
    assert_equal(poll.starts_on.advance(:days => 7), poll.ends_on)
  end

  test "shouldnt_touch_non_solapping_poll" do
    poll = self.new_poll_with({
      :terms => @poll1.terms[0].id,
      :starts_on => @poll1.ends_on.advance(:days => 1),
      :ends_on => @poll1.ends_on.advance(:days => 9),
    })
    assert poll.save, poll.errors.full_messages_html
    assert_equal(@poll1.ends_on.advance(:days => 1), poll.starts_on)
    assert_equal(@poll1.ends_on.advance(:days => 9), poll.ends_on)
  end

  protected
  DEFAULT_OPTS = {
      :ends_on => 2.days.since,
      :starts_on => 1.day.since,
      :options_new => "opcion1\nopcion2",
      :state => Cms::PENDING,
      :terms => 1,
      :title => "holitas carambolitas",
      :user_id => 1,
  }
  def new_poll_with(opts)
    Poll.new(DEFAULT_OPTS.clone.update(opts))
  end
end
