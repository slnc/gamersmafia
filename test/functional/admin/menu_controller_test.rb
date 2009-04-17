require 'test_helper'

class Admin::MenuControllerTest < ActionController::TestCase
  
  test "index" do
    sym_login 1
    get :index
    assert_response :success
  end
end
