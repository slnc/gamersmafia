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
  
  test "tildes should work" do
    @uct = UsersContentsTag.new(:user_id => 1, :content_id => 1, :original_name => 'holá')
    assert @uct.save
    assert_equal 'hola', @uct.term.slug
  end
  
  test "no duplicated terms" do
    [17, 1].each do |tid|
      t = Term.find(tid)
      @uct = UsersContentsTag.new(:user_id => 1, :content_id => 1, :original_name => t.name)
      assert !@uct.save
    end
  end
  
  test "eñe should work" do
    @uct = UsersContentsTag.new(:user_id => 1, :content_id => 1, :original_name => 'ñ')
    assert @uct.save
  end
  
  test "official tags should be just the top popular tags" do
    @c1 = Content.find(1)
    @u1 = User.find(1)
    @u2 = User.find(2)
    @u3 = User.find(3)
    t_count = Term.contents_tags.count
    UsersContentsTag.tag_content(@c1, @u1, 'anime foo bar baz')
    UsersContentsTag.tag_content(@c1, @u2, 'foo bar  gorvachob baz')
    UsersContentsTag.tag_content(@c1, @u3, 'foo bar baz kapoing')
    assert_equal t_count + 6, Term.contents_tags.count
    tofind = %w(foo bar baz)
    @c1.top_tags.each do |t|
      tofind.delete(t.name)
    end
    assert_equal [], tofind
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
  
  test "delete_tag should recalculate contents_terms" do
    @c1 = Content.find(1)
    @u1 = User.find(1)
    UsersContentsTag.tag_content(@c1, @u1, 'fumanchu')
    assert_count_decreases(ContentsTerm) do
      UsersContentsTag.find(:first, :order => 'id DESC').destroy
    end
    assert_equal [], @c1.top_tags
  end
  
  test "deleting because too many top tags should work" do
    ct_old = ContentsTerm.count
    test_official_tags_should_be_just_the_top_popular_tags
    UsersContentsTag.recalculate_content_top_tags(@c1, 1)
    assert_equal ct_old + 1, ContentsTerm.count
  end
end
