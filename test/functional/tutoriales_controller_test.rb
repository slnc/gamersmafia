require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'

class TutorialesControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Tutorial', :form_vars => {:title => 'footapang', :description => 'bartapang', :main => 'aaa'}, :categories_terms => 19


  test "should work on bazar" do
    @request.host = App.domain_bazar
    get :index
    assert_response :success
  end
end
