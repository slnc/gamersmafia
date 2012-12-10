# -*- encoding : utf-8 -*-
require 'test_helper'

class DownloadTest < ActiveSupport::TestCase

  def setup
    @download = Download.published.first
  end

  test "should_update_md5_hash_after_creating_with_file" do
    @d = Download.create({
        :user_id => 1,
        :terms => 1,
        :title => 'mi archivito',
        :file => fixture_file_upload('/files/images.zip', 'application/zip'),
    })
    assert !@d.new_record?
    assert /images\.zip/ =~ @d.file
    assert_equal(file_hash("#{Rails.root}/test/fixtures/files/images.zip"),
                 @d.file_hash_md5)
  end

  test "should_update_md5_hash_after_updating_with_new_file" do
    test_should_update_md5_hash_after_creating_with_file
    assert_equal true, @d.update_attributes({:file => fixture_file_upload('/files/buddha.jpg', 'image/jpeg')})
    assert /buddha\.jpg/ =~ @d.file
    assert_equal file_hash("#{Rails.root}/test/fixtures/files/buddha.jpg"), @d.file_hash_md5
  end

  test "shouldnt_allow_to_create_an_image_with_existing_md5hash" do
    test_should_update_md5_hash_after_creating_with_file
    d2 = Download.create({
        :user_id => 1,
        :terms => 1,
        :title => 'mi archivito2',
        :file => fixture_file_upload('/files/images.zip', 'application/zip'),
    })
    assert_equal true, d2.new_record?
    assert_not_nil d2.errors[:file]
  end

  test "create_symlink_should_work" do
    test_should_update_md5_hash_after_updating_with_new_file
    mcookie = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    cookiedir = "#{Rails.root}/public/storage/d/#{mcookie}"
    FileUtils.rm_rf(cookiedir) if File.exists?(cookiedir)
    Download.create_symlink(mcookie, @d.file)
    assert File.exists?(cookiedir)
    assert File.exists?("#{cookiedir}/#{File.basename(@d.file)}")
  end

  test "check_invalid_downloads_with_valid_download" do
    d1 = @download
    d1.file = fixture_file_upload('/files/images.zip', 'application/zip')
    assert d1.save
    alerts = Alert.count
    User.db_query("DELETE FROM downloads WHERE id <> 1")
    Download.check_invalid_downloads
    d1.reload
    assert d1.file.index('images.zip')
    assert_equal alerts, Alert.count
  end

  test "check_invalid_downloads_with_valid_download_with_mirrors" do
    d1 = @download
    assert_equal 1, d1.download_mirrors.size
    alerts = Alert.count
    User.db_query("DELETE FROM downloads WHERE id <> 1")
    Download.check_invalid_downloads
    d1.reload
    assert_equal alerts, Alert.count
  end

  test "check_invalid_downloads_with_invalid_download_without_mirrors" do
    d1 = @download
    d1.download_mirrors.clear
    assert d1.update_attributes({:file => nil})
    assert_nil d1.file
    alerts = Alert.count
    User.db_query("DELETE FROM downloads WHERE id <> 1")
    Download.check_invalid_downloads
    d1.reload
    assert_equal alerts + 1, Alert.count
  end
end
