# -*- encoding : utf-8 -*-
require 'test_helper'

class OrganizationsTest < ActiveSupport::TestCase
  test "find_organization_by_content_should_work_with_factions_content" do
    n1 = News.find(1)
    org = Organizations.find_by_content(n1)
    assert_equal 'Faction', org.class.name
    assert_equal n1.main_category.root.code, org.code
  end

  test "find_organization_by_content_should_work_with_districts_content" do
    n65 = News.find(65)
    org = Organizations.find_by_content(n65)
    assert_equal 'BazarDistrict', org.class.name
    assert_equal n65.main_category.code, org.code
  end

  test "find_organization_by_content_should_work_with_categorizable_content_in_no_organization" do
    n66 = News.find(66)
    assert Organizations.find_by_content(n66).nil?
  end

  test "find_organization_by_content_should_work_with_noncategorizable" do
    assert Organizations.find_by_content(Funthing.find(1)).nil?
  end
end
