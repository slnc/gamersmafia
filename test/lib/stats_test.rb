# -*- encoding : utf-8 -*-
require 'test_helper'

class StatsTest < ActiveSupport::TestCase
  test "compute_daily_stats" do
    Stats::Metrics.compute_daily_metrics(DateTime.parse("2006-01-01"))
    assert_equal("3", Keystore.get("kpi.core.active_users_30d.2006-01-01"))
  end
end

