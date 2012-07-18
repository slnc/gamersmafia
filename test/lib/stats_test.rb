# -*- encoding : utf-8 -*-
require 'test_helper'

class StatsTest < ActiveSupport::TestCase
  test "compute_daily_stats" do
    Stats::Metrics.expects(:compute_monthly_metric).returns([100, 25])
    Stats::Metrics.expects(:compute_yearly_metric).returns([1000, 250])
    Stats::Metrics.compute_daily_metrics(DateTime.parse("2006-01-01"))
    assert_equal("3", Keystore.get("kpi.core.active_users_30d.2006-01-01"))
    assert_equal("100", Keystore.get("kpi.core.active_users_30d.2006-01.avg"))
    assert_equal("25", Keystore.get("kpi.core.active_users_30d.2006-01.sd"))
    assert_equal("1000", Keystore.get("kpi.core.active_users_30d.2006.avg"))
    assert_equal("250", Keystore.get("kpi.core.active_users_30d.2006.sd"))
  end

  test "compute_monthly_metric" do
    Keystore.expects(:get).times(31).returns((Random.rand * 100).to_i.to_s)
    (mean, sd) = Stats::Metrics.compute_monthly_metric(
        "kpi.core.active_users_30d", DateTime.parse("2006-01-01"))
    assert_not_nil mean
    assert_not_nil sd
  end

  test "compute_yearly_metric" do
    Keystore.expects(:get).times(365).returns((Random.rand * 100).to_i.to_s)
    (mean, sd) = Stats::Metrics.compute_yearly_metric(
        "kpi.core.active_users_30d", DateTime.parse("2006-01-01"))
    assert_not_nil mean
    assert_not_nil sd
  end
end

