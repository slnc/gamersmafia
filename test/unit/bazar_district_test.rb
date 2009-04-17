require 'test_helper'

class BazarDistrictTest < ActiveSupport::TestCase
  
  def test_should_create_basic_content_categories
    newbd = BazarDistrict.new(:name => 'Yoga', :code => 'yoga')
    assert newbd.save
    assert_not_nil BazarDistrictPortal.find_by_code('yoga')
    
    t = Term.find(:first, :conditions => ['bazar_district_id = ? AND parent_id IS NULL', newbd.id])
    assert t
    assert_equal newbd.name, t.name
    assert_equal newbd.code, t.slug
    assert t.children.count > 0 
  end
  
  def test_single_person_staff
    bd = BazarDistrict.find(:first)
    assert !bd.has_don?
    assert !bd.has_mano_derecha?
    bd.update_don(User.find(1))
    assert bd.has_don?
    assert_equal 1, bd.don.id
    bd.update_mano_derecha(User.find(2))
    assert bd.has_mano_derecha?
    assert_equal 2, bd.mano_derecha.id
    
    # test no boss de varios a la vez
    bd2 = BazarDistrict.find(:first, :conditions => ['id <> ?', bd.id])
    bd2.update_don(User.find(1))
    assert_equal 1, bd2.don.id
    bd.reload
    assert !bd.has_don?
    
    # test update a nil
    bd2.update_don(nil)
    assert !bd2.has_don?
  end
  
  def test_user_is_editor_if_boss
    bd = BazarDistrict.find(1)
    ctype = ContentType.find(:first)
    u59 = User.find(59)
    assert !bd.user_is_editor_of_content_type?(u59, ctype)
    bd.update_don(u59)
    assert bd.user_is_editor_of_content_type?(u59, ctype)
  end
  
  def test_user_is_editor_if_underboss
    bd = BazarDistrict.find(1)
    ctype = ContentType.find(:first)
    u59 = User.find(59)
    assert !bd.user_is_editor_of_content_type?(u59, ctype)
    bd.update_mano_derecha(u59)
    assert bd.user_is_editor_of_content_type?(u59, ctype)
  end
  
  def test_user_is_editor_if_sicario
    bd = BazarDistrict.find(1)
    ctype = ContentType.find(:first)
    u59 = User.find(59)
    assert !bd.user_is_editor_of_content_type?(u59, ctype)
    bd.add_sicario(u59)
    assert bd.user_is_editor_of_content_type?(u59, ctype)
  end
  
  def atest_rename_bazar_district_code
    # TODO test
  end
end
