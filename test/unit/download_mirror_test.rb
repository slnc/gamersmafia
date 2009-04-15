require File.dirname(__FILE__) + '/../test_helper'

class DownloadMirrorTest < ActiveSupport::TestCase

  def setup
    @download_mirror = DownloadMirror.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of DownloadMirror,  @download_mirror
  end
end
