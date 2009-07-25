require 'test_helper'

class UsersContentsTagTest < ActiveSupport::TestCase
  test "should create term if not matching" do
    assert_count_increases(Term) do
      assert_count_increases(UsersContentsTag) do
        @uct = UsersContentsTag.create(:user_id => 1, :content_id => 1, :original_name => 'guapo')
        assert !@uct.nil?
      end
    end
  end
  
  test "should only allow valid tag characters" do
    @uct = UsersContentsTag.new(:user_id => 1, :content_id => 1, :original_name => '~)!"U(#~)')
    assert !@uct.save
  end
  
  test "should ignore case" do
    assert_count_increases(UsersContentsTag) do
      @uct = UsersContentsTag.create(:user_id => 1, :content_id => 1, :original_name => 'HOLA')
    end
    
    @uct2 = UsersContentsTag.new(:user_id => 1, :content_id => 1, :original_name => 'hola')
    assert !@uct2.save
  end
  
  test "tag_content should create tags its first time" do
    tc = UsersContentsTag.count
    @c1 = Content.find(1)
    @u1 = User.find(1)
    UsersContentsTag.tag_content(@c1, @u1, 'fumanchu es tu tio')
    assert_equal tc + 4, UsersContentsTag.count
    tofind = %w(fumanchu es tu tio)
    @c1.users_contents_tags.find(:all, :conditions => ['user_id = ?', @u1.id], :order => 'created_on DESC').each do |t|
      tofind.delete(t.original_name)
    end
    assert_equal [], tofind 
  end
  
  test "tag_content should delete tags once they were created" do
    test_tag_content_should_create_tags_its_first_time
    UsersContentsTag.tag_content(@c1, @u1, 'lel')
    assert_equal 1, @c1.users_contents_tags.count
    assert @c1.users_contents_tags.find_by_original_name('lel') 
  end
end