require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'
require 'reviews_controller'

# Re-raise errors caught by the controller.
class ReviewsController; def rescue_action(e) raise e end; end

class ReviewsControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Review', :form_vars => {:title => 'footapang', :description => 'bartapang', :main => 'oooo'}, :root_terms => 1

  def setup
    @controller = ReviewsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
end
