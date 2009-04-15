require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'
require 'tutoriales_controller'

# Re-raise errors caught by the controller.
class TutorialesController; def rescue_action(e) raise e end; end

class TutorialesControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Tutorial', :form_vars => {:title => 'footapang', :description => 'bartapang', :main => 'aaa'}, :categories_terms => 19

  def setup
    @controller = TutorialesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
end
