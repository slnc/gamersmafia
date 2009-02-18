require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'
require 'entrevistas_controller'

# Re-raise errors caught by the controller.
class EntrevistasController; def rescue_action(e) raise e end; end

class EntrevistasControllerTest < Test::Unit::TestCase
  test_common_content_crud :name => 'Interview', :form_vars => {:title => 'footapang', :description => 'bartapang', :main => 'aaa', :interviews_category_id => 1}

  def setup
    @controller = EntrevistasController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
end
