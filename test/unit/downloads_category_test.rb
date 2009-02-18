require File.dirname(__FILE__) + '/../test_helper'

class DownloadsCategoryTest < Test::Unit::TestCase

  def setup
    @downloads_category = DownloadsCategory.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of DownloadsCategory,  @downloads_category
  end
end
