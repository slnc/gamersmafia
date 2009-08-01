require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  test "index should work" do
    get :index
    assert_response :success
  end
  
  test "show should work" do
    
    t = Term.create(:taxonomy => 'ContentsTag', :name => 'foo')
    t.link(Content.find(:first))
    get :show, :id => t.id
    assert_response :success
  end
end
