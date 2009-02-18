require File.dirname(__FILE__) + '/../test_helper'

class ImageTest < Test::Unit::TestCase

  def setup
    @image = Image.find(1)
  end

  def test_assert_truth
  end
  
  def test_changing_an_image_category_should_delete_potd_if_new_category_is_in_special_and_current_potd
    im = Image.new({:description => 'foo', :images_category_id => 2, :user_id => 1, :state => Cms::PUBLISHED})
    assert_equal true, im.save
    p = Potd.new({:image_id => im.id, :date => Time.now})
    assert_equal true, p.save
    im.images_category_id = ImagesCategory.find_by_code('bazar').id
    assert_equal true, im.save, im.errors.full_messages_html
    assert_nil Potd.find_by_id(p.id)
  end
  
  # TODO copypaste de download
  # TODO esto va a a plugin de file_column!
  def test_should_update_md5_hash_after_creating_with_image
    @d = Image.create({:user_id => 1, :images_category_id => 1, :file => fixture_file_upload('/files/babe.jpg', 'application/zip')})
    assert_equal false, @d.new_record?
    assert /babe\.jpg/ =~ @d.file
    assert_equal file_hash("#{RAILS_ROOT}/test/fixtures/files/babe.jpg"), @d.file_hash_md5
  end
  
  def test_should_update_md5_hash_after_updating_with_new_image
    test_should_update_md5_hash_after_creating_with_image
    assert_equal true, @d.update_attributes({:file => fixture_file_upload('/files/buddha.jpg', 'image/jpeg')})
    assert /buddha\.jpg/ =~ @d.file
    assert_equal file_hash("#{RAILS_ROOT}/test/fixtures/files/buddha.jpg"), @d.file_hash_md5
  end
  
  # TODO this should be done by silencecore_imagecolumn
  def test_shouldnt_allow_to_create_an_image_with_existing_md5hash
    test_should_update_md5_hash_after_creating_with_image
    d2 = Image.create({:user_id => 1, :images_category_id => 1, :file => fixture_file_upload('/files/babe.jpg', 'application/zip')})
    assert_equal true, d2.new_record?
    assert_not_nil d2.errors[:file]
  end
end
