require 'test_helper'

class HasSlugTestRecord < ActiveRecord::Base
  has_slug :name
end

class HasSlugTest < ActiveSupport::TestCase
  def setup
    ActiveRecord::Base.db_query('CREATE TABLE has_slug_test_records(id serial primary key not null unique, name varchar, slug varchar)')
  end

  test "should_assign_slug_if_nil" do
    c = HasSlugTestRecord.new
    c.name = 'foo'
    c.save
    assert_equal 'foo', c.slug
  end

  test "should_assign_slug_if_blank" do
    c = HasSlugTestRecord.new
    c.name = 'foo'
    c.slug = ' '
    c.save
    assert_equal 'foo', c.slug
  end

  test "should_assign_pretty_slug" do
    c = HasSlugTestRecord.new
    c.name = '¿El Oso Madroño.guaperás del mund!>·")%("'
    c.save
    assert_equal 'el-oso-madronoguaperas-del-mund', c.slug
  end

  test "should_assign_pretty_slug_even_if_repeated" do
    test_should_assign_pretty_slug
    c = HasSlugTestRecord.new
    c.name = '¿El Oso Madroño.guaperás del mund!>·")%("'
    c.save
    assert_equal 'el-oso-madronoguaperas-del-mund-1', c.slug

    c = HasSlugTestRecord.new
    c.name = '¿El Oso Madroño.guaperás del mund!>·")%("'
    c.save
    assert_equal 'el-oso-madronoguaperas-del-mund-2', c.slug
  end

  def teardown
    ActiveRecord::Base.db_query('DROP TABLE has_slug_test_records')
  end
end