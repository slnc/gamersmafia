require File.dirname(__FILE__) + '/../../test_helper'

class Admin::MenuControllerTest < ActionController::TestCase
  
  def test_index
    sym_login 1
    get :index
    assert_response :success
  end
end
