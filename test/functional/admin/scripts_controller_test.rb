require 'test_helper'

class Admin::ScriptsControllerTest < ActionController::TestCase
  test "index" do
    sym_login 1
    get :index
    assert_response :success
  end
  
  test "fix_categories" do
    sym_login 1
#    post :fix_categories
#    assert_response :redirect
  end
  
  test "categories_count" do
    sym_login 1
#    post :fix_categories_count
#    assert_response :redirect
  end
end
