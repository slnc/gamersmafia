require 'test_helper'
load Rails.root + '/Rakefile'

class WeeklyRakeTest < ActiveSupport::TestCase
  include Rake

  def setup
    overload_rake_for_tests
  end

  test "should_properly_pay_faction_wages_only_boss" do
    u1 = User.find(1)
    f1 = Faction.find(1)
    f1.update_boss(u1)
    orig = u1.cash
    User.db_query("INSERT INTO stats.portals(portal_id, created_on, karma) VALUES (#{Portal.find_by_code(f1.code).id}, now()::date, 100)")
    Rake::Task['gm:weekly'].send :pay_organizations_wages
    u1.reload
    assert_equal (orig + 5).to_i, u1.cash.to_i
  end

  test "should_properly_pay_faction_wages_boss_and_underboss" do
    u1 = User.find(1)
    u2 = User.find(2)
    f1 = Faction.find(1)
    f1.update_boss(u1)
    f1.update_underboss(u2)
    orig1 = u1.cash
    orig2 = u2.cash
    User.db_query("INSERT INTO stats.portals(portal_id, created_on, karma) VALUES (#{Portal.find_by_code(f1.code).id}, now()::date, 1000)")
    Rake::Task['gm:weekly'].send :pay_organizations_wages
    u1.reload
    u2.reload
    assert_equal (orig1 + 30).to_i, u1.cash.to_i
    assert_equal (orig2 + 20).to_i, u2.cash.to_i
  end

    test "should_properly_pay_bazar_district_wages_only_don" do
    u1 = User.find(1)
    f1 = BazarDistrict.find(1)
    f1.update_don(u1)
    orig = u1.cash
    User.db_query("INSERT INTO stats.portals(portal_id, created_on, karma) VALUES (#{Portal.find_by_code(f1.code).id}, now()::date, 100)")
    Rake::Task['gm:weekly'].send :pay_organizations_wages
    u1.reload
    assert_equal (orig + 5).to_i, u1.cash.to_i
  end

  test "should_properly_pay_bazar_district_wages_don_and_mano_derecha" do
    u1 = User.find(1)
    u2 = User.find(2)
    f1 = BazarDistrict.find(1)
    f1.update_don(u1)
    f1.update_mano_derecha(u2)
    orig1 = u1.cash
    orig2 = u2.cash
    User.db_query("INSERT INTO stats.portals(portal_id, created_on, karma) VALUES (#{Portal.find_by_code(f1.code).id}, now()::date, 1000)")
    Rake::Task['gm:weekly'].send :pay_organizations_wages
    u1.reload
    u2.reload
    assert_equal (orig1 + 30).to_i, u1.cash.to_i
    assert_equal (orig2 + 20).to_i, u2.cash.to_i
  end
end
