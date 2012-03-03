require 'test_helper'

class ImageTest < ActiveSupport::TestCase
  # TODO copypaste de download
  # TODO esto va a a plugin de file_column!
  test "should_update_md5_hash_after_creating_with_image" do
    @download = Image.create(
        :user_id => 1,
        :terms => 1,
        :file => fixture_file_upload('/files/babe.jpg', 'application/zip'),
    )

    assert !@download.new_record?
    assert(
      /babe\.jpg/ =~ @download.file,
      "babe.jpg not found in '#{@download.file} #{@download.file.class.name}'")
    assert_equal(file_hash("#{Rails.root}/test/fixtures/files/babe.jpg"),
                 @download.file_hash_md5)
  end

  test "should_update_md5_hash_after_updating_with_new_image" do
    test_should_update_md5_hash_after_creating_with_image
    assert_equal true, @download.update_attributes({:file => fixture_file_upload('/files/buddha.jpg', 'image/jpeg')})
    assert /buddha\.jpg/ =~ @download.file
    assert_equal file_hash("#{Rails.root}/test/fixtures/files/buddha.jpg"), @download.file_hash_md5
  end

  # TODO this should be done by silencecore_imagecolumn
  test "shouldnt_allow_to_create_an_image_with_existing_md5hash" do
    test_should_update_md5_hash_after_creating_with_image
    d2 = Image.create({:user_id => 1, :terms => 1, :file => fixture_file_upload('/files/babe.jpg', 'application/zip')})
    assert_equal true, d2.new_record?
    assert_not_nil d2.errors[:file]
  end
end
