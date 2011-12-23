require File.dirname(__FILE__) + '/../../../../test/test_helper'

class ActsAsRootableTest < Test::Unit::TestCase
  def setup
    # Creamos dummy arecord object
    ActiveRecord::Base.db_query('CREATE TABLE acts_as_rootable_mock_records (id serial primary key not null unique, name varchar, parent_id int references acts_as_rootable_mock_records(id), root_id int references acts_as_rootable_mock_records(id))')
  end

  def test_sanity_check
    mock = ActsAsRootableMockRecord.new({:name => 'foo'})
    assert_equal true, mock.save
    assert_not_nil mock.destroy
  end

  def test_should_set_root_id_to_self_id_on_creation_if_no_parent_id
    greatfather = ActsAsRootableMockRecord.create({:name => 'greatfather'})
    assert_not_nil greatfather.id
    assert_equal greatfather.id, greatfather.root_id
  end

  def test_should_set_root_id_to_parent_id_on_creation_if_parent_id
    greatfather = ActsAsRootableMockRecord.create({:name => 'greatfather'})
    father = greatfather.children.create({:name => 'father'})
    assert_equal greatfather.id, father.root_id

    child = father.children.create({:name => 'child'})
    assert_equal greatfather.id, child.root_id
  end

  def test_should_set_root_id_to_new_root_id_on_modification_of_parent_id
    test_should_set_root_id_to_parent_id_on_creation_if_parent_id
    greatfather = ActsAsRootableMockRecord.find_by_name('greatfather')
    blackgreatfather = ActsAsRootableMockRecord.create({:name => 'blackgreatfather'})
    blackfather = blackgreatfather.children.create({:name => 'blackfather'})
    child = ActsAsRootableMockRecord.find_by_name('child')
    child.parent_id = blackfather.id
    child.save
    assert_equal blackgreatfather.id, child.root_id
  end

  def test_should_set_root_id_to_self_id_if_modified_to_have_no_parents
    test_should_set_root_id_to_parent_id_on_creation_if_parent_id
    child = ActsAsRootableMockRecord.find_by_name('child')
    child.parent_id = nil
    assert_equal true, child.save
    assert_equal child.id, child.root_id
  end

  # TODO cuando hay un tag con más de una referencia comprobar que
  # last_tagged_on y que references se guardan bien
  
  def teardown
    # destruimos objeto de prueba
    ActiveRecord::Base.db_query('DROP TABLE acts_as_rootable_mock_records')
  end
end

class ActsAsRootableMockRecord < ActiveRecord::Base
  acts_as_tree
  acts_as_rootable
end
