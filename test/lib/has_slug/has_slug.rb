require File.dirname(__FILE__) + '/../../../test/test_helper'

class HasSlugTest < Test::Unit::TestCase
  def setup
    ActiveRecord::Base.db_query('CREATE TABLE has_slug_test_records(id serial primary key not null unique, name varchar, slug varchar)')
  end

  def test_should_assign_slug_if_nil
    c = HasSlugTestRecord.new
    c.name = 'foo'
    c.save
    assert_equal 'foo', c.slug
  end

  def test_should_assign_slug_if_blank
    c = HasSlugTestRecord.new
    c.name = 'foo'
    c.slug = ' '
    c.save
    assert_equal 'foo', c.slug
  end

  def test_should_assign_pretty_slug
    c = HasSlugTestRecord.new
    c.name = '¿El Oso Madroño.guaperás del mund!>·")%("'
    c.save
    assert_equal 'el-oso-madronoguaperas-del-mund', c.slug
  end

  def test_should_assign_pretty_slug_even_if_repeated
    test_should_assign_pretty_slug
    c = HasSlugTestRecord.new
    c.name = '¿El Oso Madroño.guaperás del mund!>·")%("'
    c.save
    assert_equal 'el-oso-madronoguaperas-del-mund_1', c.slug

    c = HasSlugTestRecord.new
    c.name = '¿El Oso Madroño.guaperás del mund!>·")%("'
    c.save
    assert_equal 'el-oso-madronoguaperas-del-mund_2', c.slug
  end

  def teardown
    ActiveRecord::Base.db_query('DROP TABLE has_slug_test_records')
  end
end

class HasSlugTestRecord < ActiveRecord::Base
  has_slug :name
end