require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  
  test "index should work without tags" do
    get :index
    assert_response :success
  end
  
  test "index should work with tags" do
    t = Term.create(:taxonomy => 'ContentsTag', :name => 'foo')
    t.link(Content.find(:first))
    
    get :index
    assert_response :success
  end
  
  test "show should work" do
    t = Term.create(:taxonomy => 'ContentsTag', :name => 'foo')
    t.link(Content.find(:first))
    get :show, :id => t.slug
    assert_response :success
  end
end
