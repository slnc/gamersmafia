require 'test_helper'

class ActionViewTestContainer
  include ActionViewMixings
end

class ActionViewMixingsTest < ActiveSupport::TestCase
  def setup
    @action_view = ActionViewTestContainer.new
  end

  test "format interval should work 8 days ago" do
    eight_days_ago = Time.now - 8.days.ago
    assert_equal('1 semana',
                 @action_view.format_interval(eight_days_ago, 'semanas', true))
  end

  test "format interval should work 1 hour ago" do
    plus_one_hour_ago = Time.now - 61.minutes.ago
    assert_equal('1 hora',
                 @action_view.format_interval(plus_one_hour_ago, 'horas', true))
  end

  test "format interval should work 59 mins ago" do
    one_hour_ago = Time.now - 1.hour.ago
    assert_equal('59 mins',
                 @action_view.format_interval(one_hour_ago, 'horas', true))
  end
end

