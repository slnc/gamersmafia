require 'test_helper'

class Admin::ScriptsControllerTest < ActionController::TestCase
  def test_index
    sym_login 1
    get :index
    assert_response :success
  end
  
  def test_fix_categories
    sym_login 1
#    post :fix_categories
#    assert_response :redirect
  end
  
  def test_categories_count
    sym_login 1
#    post :fix_categories_count
#    assert_response :redirect
  end
end
