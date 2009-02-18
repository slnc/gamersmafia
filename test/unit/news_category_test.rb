require File.dirname(__FILE__) + '/../test_helper'

class NewsCategoryTest < Test::Unit::TestCase

  def setup
    @news_category = NewsCategory.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of NewsCategory,  @news_category
  end
end
