require 'test_helper'

class DemoTest < ActiveSupport::TestCase
  DEFS = {:terms => 1, :title => '', :games_mode_id => 1, :demotype => Demo::DEMOTYPES[:official], :user_id => 1}
  DEFS_CLAN = {:terms => 1, :title=> '', :games_mode_id => 2, :demotype => Demo::DEMOTYPES[:official], :user_id => 1}
  
  test "should_not_be_able_to_save_if_missing_not_null_fields" do
    assert_equal true, Demo.create({}).new_record?
  end
  
  test "should_not_be_able_to_save_if_missing_entity1" do
    assert_equal true, Demo.create(DEFS).new_record?
  end
  
  test "should_not_be_able_to_save_if_missing_entity2_and_not_specifically_tutorial" do
    assert_equal true, Demo.create(DEFS.merge({:entity1_external => 'bar'})).new_record?
  end
  
  test "should_be_able_to_save_if_missing_entity2_and_specifically_tutorial" do
    d = Demo.create(DEFS.merge({:entity1_external => 'bar', :demotype => Demo::DEMOTYPES[:tutorial]}))
    assert_equal false, d.new_record?, d.errors.full_messages
  end
  
  
  test "should_set_name_based_on_entities_before_saving_with_users" do
    @d = Demo.new(DEFS.merge({:entity1_external => 'Fulanito', :entity2_local_id => 1}))
    assert_equal true, @d.save, @d.errors.full_messages
    assert_equal "Fulanito - superadmin", @d.title
  end  
  
  test "should_set_name_based_on_entities_updating_existing_demo" do
    test_should_set_name_based_on_entities_before_saving_with_users
    @d.entity1_external = 'p!tufos.moh'
    @d.entity2_external = 'peons'
    @d.entity1_local_id = nil
    @d.entity2_local_id = nil
    assert_equal true, @d.save, @d.errors.full_messages
    assert_equal "p!tufos.moh - peons", @d.title
  end
  
  test "should_set_name_based_on_entities_before_saving_with_clans" do
    @d = Demo.new(DEFS.merge({:entity1_external => 'Fulanito', :entity2_local_id => 1}))
    assert_equal true, @d.save, @d.errors.full_messages
    assert_equal "Fulanito - superadmin", @d.title
  end  
  
  test "should_set_name_based_on_entities_updating_existing_demo" do
    test_should_set_name_based_on_entities_before_saving_with_clans
    @d.entity1_external = 'Pocholito'
    @d.entity2_external = 'Manolito'
    @d.entity1_local_id = nil
    @d.entity2_local_id = nil
    assert_equal true, @d.save, @d.errors.full_messages
    assert_equal "Pocholito - Manolito", @d.title
  end
end
