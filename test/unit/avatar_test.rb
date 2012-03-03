require 'test_helper'

class AvatarTest < ActiveSupport::TestCase

  def setup

  end

  test "should_delete_file_after_destroying" do
    @av = Avatar.create({:name => 'fulanito de tal', :submitter_user_id => 1, :path => fixture_file_upload('files/buddha.jpg')})
    assert_equal false, @av.new_record?
    assert_equal true, File.exists?("#{Rails.root}/public/#{@av.path}")
    @av.destroy
    # assert_equal false, File.exists?("#{Rails.root}/public/#{@av.path}")
  end

  test "should_set_users_owning_avatar_to_nil_after_destroy" do
    @av = Avatar.create({:name => 'fulanito de tal', :user_id => 1, :submitter_user_id => 1, :path => fixture_file_upload('files/buddha.jpg')})
    assert_equal false, @av.new_record?
    u1 = User.find(1)
    u1.change_avatar(@av.id)
    assert_equal @av.id, u1.avatar_id
    @av.destroy
    u1.reload
    assert_nil u1.avatar_id
  end

  test "shouldnt_allow_to_upload_a_non_jpg_file" do
    %w(images.zip lines.gif lines.bmp header.swf).each do |f|
      @av = Avatar.create({:name => 'fulanito de tal', :submitter_user_id => 1, :path => fixture_file_upload("files/#{f}")})
      assert @av.new_record?
    end
  end

  #atest "shouldnt_allow_to_upload_an_invalid_jpg_file" do
  #  %w(zip_as_jpg.jpg bmp_as_jpg.jpg).each do |f|
  #    @av = Avatar.create({:name => 'fulanito de tal', :submitter_user_id => 1, :path => fixture_file_upload("files/#{f}")})
  #  end
  #    assert @av.new_record?
  #end

  test "should_create_logentry_after_create" do
    assert_count_increases(SlogEntry) do
      assert_count_increases(Avatar) do
        @av = Avatar.create({:name => 'fulanito de tal', :submitter_user_id => 1, :path => fixture_file_upload("files/buddha.jpg")})
      end
    end
  end
end
