require 'test_helper'

class UsersRoleTest < ActiveSupport::TestCase
  test "should change underboss to boss if boss leaves a faction" do
    f = Faction.find(:first)
    u1 = User.find(1)
    f.update_boss(u1)
    f.update_underboss(User.find(2))
    assert_equal 1, f.boss.id
    assert_equal 2, f.underboss.id
    u1.users_roles.clear
    f.reload
    assert_equal 2, f.boss.id
    assert !f.has_underboss?
  end

  test "should change mano derecha to don if don leaves a district" do
    bd = BazarDistrict.find(:first)
    u1 = User.find(1)
    bd.update_don(u1)
    bd.update_mano_derecha(User.find(2))
    assert_equal 1, bd.don.id
    assert_equal 2, bd.mano_derecha.id
    u1.users_roles.clear
    bd.reload
    assert_equal 2, bd.don.id
    assert !bd.has_mano_derecha?
  end

  test "should update users is_faction_leader when losing faction boss" do
    f = Faction.find(:first)
    u1 = User.find(2)
    f.update_boss(u1)
    u1.reload
    assert u1.is_faction_leader?
    u1.users_roles.each do |ur|
      ur.destroy
    end

    u1.reload
    assert !u1.is_faction_leader?
  end

  test "should update users is_faction_leader when losing faction underboss" do
    f = Faction.find(:first)
    u1 = User.find(2)
    f.update_underboss(u1)
    u1.reload
    assert u1.is_faction_leader?
    u1.users_roles.each do |ur|
      ur.destroy
    end

    u1.reload
    assert !u1.is_faction_leader?
  end

  test "should update users is_faction_leader when losing district don" do
    f = BazarDistrict.find(:first)
    u1 = User.find(2)
    f.update_don(u1)
    u1.reload
    assert u1.is_district_leader?
    u1.users_roles.each do |ur|
      ur.destroy
    end

    u1.reload
    assert !u1.is_district_leader?
  end

  test "should update users is_faction_leader when losing district mano_derecha" do
    f = BazarDistrict.find(:first)
    u1 = User.find(2)
    f.update_mano_derecha(u1)
    u1.reload
    assert u1.is_district_leader?
    u1.users_roles.each do |ur|
      ur.destroy
    end

    u1.reload
    assert !u1.is_district_leader?
  end
end
