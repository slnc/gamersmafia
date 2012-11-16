# -*- encoding : utf-8 -*-
require 'test_helper'

class StatsTest < ActiveSupport::TestCase

  test "compute_daily_stats" do
    Stats::Metrics.expects(:compute_monthly_metric).returns([0.2, 0])
    Stats::Metrics.expects(:compute_monthly_metric).returns([2, 0])
    Stats::Metrics.expects(:compute_monthly_metric).returns([100, 25])
    Stats::Metrics.expects(:compute_yearly_metric).returns([0.1, 0])
    Stats::Metrics.expects(:compute_yearly_metric).returns([3, 0])
    Stats::Metrics.expects(:compute_yearly_metric).returns([1000, 250])
    Stats::Metrics.compute_daily_metrics(DateTime.parse("2006-01-01"))
    assert_equal("0.0", Keystore.get("tags.percent_set_by_ias.20060101"))
    assert_equal("0.2", Keystore.get("tags.percent_set_by_ias.200601"))
    assert_equal("0.1", Keystore.get("tags.percent_set_by_ias.2006"))
    assert_equal("0", Keystore.get("tags.subscribed_users_per_tag.20060101"))
    assert_equal("2", Keystore.get("tags.subscribed_users_per_tag.200601"))
    assert_equal("3", Keystore.get("tags.subscribed_users_per_tag.2006"))
    assert_equal("3", Keystore.get("kpi.core.active_users_30d.20060101"))
    assert_equal("100", Keystore.get("kpi.core.active_users_30d.avg.200601"))
    assert_equal("1000", Keystore.get("kpi.core.active_users_30d.avg.2006"))
    assert_equal("25", Keystore.get("kpi.core.active_users_30d.sd.200601"))
    assert_equal("250", Keystore.get("kpi.core.active_users_30d.sd.2006"))
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


  def run_update_users_karma_stats
    User.db_query(
        "UPDATE contents SET created_on = NOW() - '16 days'::interval")
    User.db_query(
        "UPDATE comments SET created_on = NOW() - '15 days'::interval")
    @c1 = Comment.find(1)
    @c1.update_attributes(:karma_points => 100)
    Stats.update_users_karma_stats
  end

  test "update_users_karma_stats" do
    self.run_update_users_karma_stats
    [@c1.portal_id].each do |portal_id|
      dbr = User.db_query(
          "SELECT karma,
                  created_on,
                  portal_id
             FROM stats.users_karma_daily_by_portal
            WHERE user_id = #{@c1.user_id}
              AND portal_id = #{portal_id}
              AND created_on = (NOW() - '15 days'::interval)::date")
      assert_equal 1, dbr.size
      assert_equal 100, dbr[0]["karma"].to_i
    end
  end

  test "update_users_daily_stats" do
    self.run_update_users_karma_stats
    Stats.update_users_daily_stats
    dbr =  User.db_query(
        "SELECT karma
           FROM stats.users_daily_stats
          WHERE user_id = #{@c1.user_id}
            AND created_on = (NOW() - '15 days'::interval)::date")
    assert_equal 1, dbr.size
    assert_equal 100, dbr[0]["karma"].to_i
  end
end

