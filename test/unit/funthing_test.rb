require 'test_helper'

class FunthingTest < ActiveSupport::TestCase
  test "funthing with youtube url whose corresponding youtube embed already exists in another funthing shouldn't cause problems" do
    f1 = Funthing.new({:title => 'foo funthing', :main => 'http://www.youtube.com/watch?v=rrNriyDJmdw', :user_id => 1})
    f2 = Funthing.new({:title => 'foo funthing2', :main => 'http://www.youtube.com/watch?v=rrNriyDJmdw', :user_id => 1})
    assert f1.save
    assert !f2.save
    assert !(Funthing::YOUTUBE_EMBED =~ f1.main)
    assert_equal f1.main, f2.main 
  end
  
  
  test "should_create_funthing" do
    ft = Funthing.new({:title => 'foo funthing', :main => 'somecode', :user_id => 1})
    assert_equal true, ft.save
    assert_not_nil Funthing.find_by_title('foo funthing')
  end
  
  test "should_not_create_funthing_if_duplicated_name" do
    test_should_create_funthing
    ft = Funthing.new({:title => 'foo funthing', :main => 'somecode2', :user_id => 1})
    assert !ft.save
  end
  
  test "should_not_create_funthing_if_duplicated_url" do
    test_should_create_funthing
    ft = Funthing.new(:title => 'foo funthing2', :main => 'somecode', :user_id => 1)
    assert !ft.save
  end
  
  test "should_not_create_funthing_if_duplicated_url_with_youtube" do
    test_should_create_funthing
    assert_equal true, Funthing.find(:first, :order => 'id desc').update_attributes({:main => 'http://www.youtube.com/watch?v=rrNriyDJmdw'})
    ft = Funthing.new({:title => 'foo funthing2', :main => 'http://www.youtube.com/watch?v=rrNriyDJmdw', :user_id => 1})
    assert !ft.save
  end
  
  test "should_automatically_transform_youtube_url_into_youtube_embed" do
    @ft = Funthing.new({:title => 'wikitapang', :main => 'http://es.youtube.com/watch?v=Fk9epgGfE7s', :user_id => 1})
    assert_equal true, @ft.save
    assert_equal '<object width="425" height="355"><param name="movie" value="http://www.youtube.com/v/Fk9epgGfE7s&rel=1"></param><param name="wmode" value="transparent"></param><embed src="http://www.youtube.com/v/Fk9epgGfE7s&rel=1" type="application/x-shockwave-flash" wmode="transparent" width="425" height="355"></embed></object>', @ft.main
  end
  
  test "should_not_touch_youtube_embed" do
    embed = '<object width="425" height="355"><param name="movie" value="http://www.youtube.com/v/Fk9epgGfE7s&rel=1"></param><param name="wmode" value="transparent"></param><embed src="http://www.youtube.com/v/Fk9epgGfE7s&rel=1" type="application/x-shockwave-flash" wmode="transparent" width="425" height="355"></embed></object>' 
    ft = Funthing.new({:title => 'wikitapang', :main => embed, :user_id => 1})
    assert_equal true, ft.save
    assert_equal embed, ft.main
  end
  
  test "dont allow javascript" do
    ft = Funthing.new({:title => 'foo funthing2', :main => '<script', :user_id => 1})
    assert_equal false, ft.save
    assert_not_nil ft.errors[:main]
  end
end
