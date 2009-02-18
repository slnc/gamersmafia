require File.dirname(__FILE__) + '/../test_helper'

class AvatarTest < Test::Unit::TestCase
  
  def setup
    
  end
  
  # Replace this with your real tests.
  def test_should_delete_file_after_destroying
    @av = Avatar.create({:name => 'fulanito de tal', :submitter_user_id => 1, :path => fixture_file_upload('files/buddha.jpg')})
    assert_equal false, @av.new_record?
    assert_equal true, File.exists?("#{RAILS_ROOT}/public/#{@av.path}")
    @av.destroy
    assert_equal false, File.exists?("#{RAILS_ROOT}/public/#{@av.path}")
  end
  
  def test_should_set_users_owning_avatar_to_nil_after_destroy
    @av = Avatar.create({:name => 'fulanito de tal', :submitter_user_id => 1, :path => fixture_file_upload('files/buddha.jpg')})
    assert_equal false, @av.new_record?
    u1 = User.find(1)
    u1.change_avatar @av.id
    assert_equal @av.id, u1.avatar_id
    @av.destroy
    u1.reload
    assert_nil u1.avatar_id
  end
  
  def test_shouldnt_allow_to_upload_a_non_jpg_file
    %w(images.zip lines.gif lines.bmp header.swf).each do |f|
      @av = Avatar.create({:name => 'fulanito de tal', :submitter_user_id => 1, :path => fixture_file_upload("files/#{f}")})
      assert_nil @av.path
    end
  end
  
  def test_shouldnt_allow_to_upload_an_invalid_jpg_file
    %w(zip_as_jpg.jpg bmp_as_jpg.jpg).each do |f|
      @av = Avatar.create({:name => 'fulanito de tal', :submitter_user_id => 1, :path => fixture_file_upload("files/#{f}")})
      assert_nil @av.path
    end
  end
  
  def test_should_create_logentry_after_create
    assert_count_increases(SlogEntry) do
      assert_count_increases(Avatar) do
        @av = Avatar.create({:name => 'fulanito de tal', :submitter_user_id => 1, :path => fixture_file_upload("files/buddha.jpg")})
      end
    end
  end
end
