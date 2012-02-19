require 'test_helper'

class CompetitionsMatchesUploadTest < ActiveSupport::TestCase

  test "create" do
    FileUtils.rm_rf("#{Rails.root}/public/storage/competitions_matches_uploads/0000/002_*")
    upload = CompetitionsMatchesUpload.new({:user_id => 1, :competitions_match_id => 1, :file => fixture_file_upload('files/image.jpg', 'image/jpeg')})
    assert_equal true, upload.save, upload.errors.full_messages_html
  end
end
