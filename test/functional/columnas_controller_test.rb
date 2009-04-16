require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'
require 'columnas_controller'

# Re-raise errors caught by the controller.
class ColumnasController; def rescue_action(e) raise e end; end

class ColumnasControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Column', :form_vars => {:title => 'footapang', :description => "abracadabra", :main => 'hellouu'}, :root_terms => 1

  def setup
    @controller = ColumnasController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
end
