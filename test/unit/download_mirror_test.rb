require 'test_helper'

class DownloadMirrorTest < ActiveSupport::TestCase

  def setup
    @download_mirror = DownloadMirror.find(1)
  end

  # Replace this with your real tests.
  test "truth" do
    assert_kind_of DownloadMirror,  @download_mirror
  end
end
