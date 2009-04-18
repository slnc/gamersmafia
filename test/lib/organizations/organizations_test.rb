require File.dirname(__FILE__) + '/../../../test/test_helper'

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
  
  test "change_organization_type_to_same" do
    assert_raises(RuntimeError) do
      Organizations.change_organization_type(Faction.find(:first), Faction)
    end
    
    assert_raises(RuntimeError) do
      Organizations.change_organization_type(BazarDistrict.find(:first), BazarDistrict)
    end
  end
  
  test "should_change_organization_type_from_faction_to_district" do
    faction = Faction.find(:first)
    faction.update_boss(User.find(1))
    faction.update_underboss(User.find(2))
    faction.add_moderator(User.find(3))
    faction.add_editor(User.find(4), ContentType.find(:first))
    Factions.user_joins_faction(User.find(5), faction)
    Avatar.create(:name => 'foo', :submitter_user_id => 1, :level => 1, :faction_id => faction.id, :path => fixture_file_upload('files/buddha.jpg', 'image/jpeg'))
    bd = Organizations.change_organization_type(faction, BazarDistrict)
    assert_equal 'BazarDistrict', bd.class.name
    assert_nil Faction.find_by_code(bd.code)
    assert BazarDistrictPortal.find_by_code(bd.code)
    assert_equal 1, bd.don.id
    assert_equal 2, bd.mano_derecha.id
    assert_equal [3, 4], bd.sicarios.collect { |u| u.id }.sort
    
    # TODO categorías viejas de contenidos tienen que haber cambiado
    # TODO las urls de los contenidos correctas
    # TODO el icono
  end
  
  test "should_not_change_organization_type_if_not_faction" do
    # TEMP
    assert_raises(RuntimeError) do
      Organizations.change_organization_type(BazarDistrict.find(:first), User)
    end
    
    assert_raises(RuntimeError) do
      Organizations.change_organization_type(BazarDistrict.find(:first), Faction)
    end
  end
end
