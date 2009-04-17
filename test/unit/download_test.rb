require 'test_helper'

class DownloadTest < ActiveSupport::TestCase
  
  def setup
    @download = Download.find(1)
  end
  
  # TODO esto va a a plugin de file_column!
  def test_should_update_md5_hash_after_creating_with_file
    @d = Download.create({:user_id => 1, :terms => 1, :title => 'mi archivito', :file => fixture_file_upload('/files/images.zip', 'application/zip')})
    assert_equal false, @d.new_record?
    assert /images\.zip/ =~ @d.file
    assert_equal file_hash("#{RAILS_ROOT}/test/fixtures/files/images.zip"), @d.file_hash_md5
  end
  
  def test_should_update_md5_hash_after_updating_with_new_file
    test_should_update_md5_hash_after_creating_with_file
    assert_equal true, @d.update_attributes({:file => fixture_file_upload('/files/buddha.jpg', 'image/jpeg')})
    assert /buddha\.jpg/ =~ @d.file
    assert_equal file_hash("#{RAILS_ROOT}/test/fixtures/files/buddha.jpg"), @d.file_hash_md5
  end
  
  # TODO this should be done by silencecore_filecolumn
  def test_shouldnt_allow_to_create_an_image_with_existing_md5hash
    test_should_update_md5_hash_after_creating_with_file
    d2 = Download.create({:user_id => 1, :terms => 1, :title => 'mi archivito2', :file => fixture_file_upload('/files/images.zip', 'application/zip')})
    assert_equal true, d2.new_record?
    assert_not_nil d2.errors[:file]
  end
  
  def test_create_symlink_should_work
    test_should_update_md5_hash_after_updating_with_new_file
    mcookie = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    cookiedir = "#{RAILS_ROOT}/public/storage/d/#{mcookie}"
    FileUtils.rm_rf(cookiedir) if File.exists?(cookiedir)
    Download.create_symlink(mcookie, @d.file)
    assert File.exists?(cookiedir)
    assert File.exists?("#{cookiedir}/#{File.basename(@d.file)}")
  end
  
  def test_check_invalid_downloads_with_valid_download
    d1 = Download.find(1)
    d1.file = fixture_file_upload('/files/images.zip', 'application/zip')
    assert d1.save
    slogentries = SlogEntry.count
    User.db_query("DELETE FROM downloads WHERE id <> 1")
    Download.check_invalid_downloads
    d1.reload
    assert d1.file.index('images.zip')
    assert_equal slogentries, SlogEntry.count
  end
  
  def test_check_invalid_downloads_with_valid_download_with_mirrors
    d1 = Download.find(1)
    assert_equal 1, d1.download_mirrors.size
    slogentries = SlogEntry.count
    User.db_query("DELETE FROM downloads WHERE id <> 1")
    Download.check_invalid_downloads
    d1.reload
    assert_equal slogentries, SlogEntry.count
  end
  
  def test_check_invalid_downloads_with_invalid_download_without_mirrors
    d1 = Download.find(1)
    d1.download_mirrors.clear
    assert d1.update_attributes({:file => nil})
    
    assert_nil d1.file
    slogentries = SlogEntry.count
    User.db_query("DELETE FROM downloads WHERE id <> 1")
    Download.check_invalid_downloads
    d1.reload
    assert_equal slogentries + 1, SlogEntry.count
  end
end
