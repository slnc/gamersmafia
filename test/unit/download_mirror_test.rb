require 'test_helper'

class DownloadMirrorTest < ActiveSupport::TestCase

  def setup
    @download_mirror = DownloadMirror.find(1)
  end

  # Replace this with your real tests.
  test "shouldn't allow incorrect url" do
    dm = DownloadMirror.new(:download_id => 1, 
                            :url => "\"><script>alet('foo');</script>")
    assert !dm.save
    
    dm = DownloadMirror.new(:download_id => 1, 
                            :url => "http://example.com/\"><script>alet('foo');" +
                            "</script>")
    assert !dm.save
    
    dm = DownloadMirror.new(:download_id => 1, :url => "http://example.com/")
    assert dm.save
  end
end
