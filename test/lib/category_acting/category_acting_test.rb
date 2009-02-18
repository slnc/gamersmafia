require File.dirname(__FILE__) + '/../../../test/test_helper'

class CategoryActingTest < Test::Unit::TestCase
  def test_should_creating_a_root_category_should_properly_initialize_attributes
    @n1 = NewsCategory.create({:name => 'cacttest1'})
    assert_not_nil @n1
    assert_equal @n1.id, @n1.root_id
    assert_nil @n1.parent_id
  end
  
  def test_should_properly_create_children
    test_should_creating_a_root_category_should_properly_initialize_attributes
    @n1child = @n1.children.create({:name => 'first_child'})
    assert_not_nil @n1child
    assert_equal @n1.id, @n1child.root_id
  end
  
  def test_should_properly_update_root_id_when_moving_a_category_from_one_root_to_another
    test_should_properly_create_children
    @n2 = NewsCategory.create({:name => 'cacttest2'})
    assert_not_nil @n2
    @n1child.parent_id = @n2.id
    @n1child.save
    assert_equal @n2.id, @n1child.root_id
  end
  
  def test_should_properly_update_root_id_when_moving_a_category_from_one_root_to_another_and_it_has_subcategories
    test_should_properly_create_children
    @n2 = NewsCategory.create({:name => 'cacttest2'})
    assert_not_nil @n2
    @n1.parent_id = @n2.id
    @n1.save
    assert_equal @n2.id, @n1.root_id
    @n1child.reload
    assert_equal @n2.id, @n1child.root_id
  end
  
  def test_should_properly_return_related_portals_if_not_matching_a_factions_code
    nc = NewsCategory.new({:name => 'catnonfaction', :code => 'nonfaction'})
    assert_equal true, nc.save
    p nc.get_related_portals
    assert_equal (FactionsPortal.count + BazarDistrictPortal.count + 1), nc.get_related_portals.size
    assert_equal 'GmPortal', nc.get_related_portals[0].class.name
  end
  
  def test_should_properly_return_related_portals_if_not_matching_a_factions_code_and_child
    nc = NewsCategory.new({:name => 'catnonfaction', :code => 'nonfaction'})
    assert nc.save
    ncchild = nc.children.create({:name => 'subcat', :code => 'subcat'})
    assert_equal true, ncchild.save
    assert_equal (FactionsPortal.count + BazarDistrictPortal.count + 1), ncchild.get_related_portals.size
    assert_equal 'GmPortal', ncchild.get_related_portals[0].class.name
  end
  
  def test_should_properly_return_related_portals_if_matching_a_factions_code
    nc = NewsCategory.find_by_code('ut')
    assert_not_nil nc
    assert_equal 3, nc.get_related_portals.size, nc.get_related_portals
    # assert_equal 'GmPortal', nc.get_related_portals[0].class.name
  end
  
  def test_get_all_children_should_properly_return_if_root_id_given
    @nc = NewsCategory.create({:name => 'catnonfaction', :code => 'nonfaction'})
    @ncchild = @nc.children.create({:name => 'subcat', :code => 'subcat'})
    @cats = @nc.get_all_children
    assert_equal 2, @cats.size
    @cats.each { |catid| assert_equal true, catid.kind_of?(Fixnum)}
    assert_equal true, @cats.include?(@nc.id)
    assert_equal true, @cats.include?(@ncchild.id)
  end
  
  def test_get_all_children_should_return_the_same_if_same_cat_asked_in_different_ways
    test_get_all_children_should_properly_return_if_root_id_given
    cats2 = @nc.get_all_children(@nc)
    assert_equal true, @cats == cats2
  end
  
  def test_get_all_children_should_properly_work_if_asking_for_non_root_id_cat
    @nc = NewsCategory.create({:name => 'catnonfaction', :code => 'nonfaction'})
    @ncchild = @nc.children.create({:name => 'subcat', :code => 'subcat'})
    @ncsubchild = @ncchild.children.create({:name => 'subsubcat', :code => 'subsubcat'})
    @cats = @ncchild.get_all_children
    assert_equal 2, @cats.size
    assert_equal true, @cats.include?(@ncchild.id)
    assert_equal true, @cats.include?(@ncsubchild.id)
  end
end