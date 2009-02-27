require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'
require 'reviews_controller'

# Re-raise errors caught by the controller.
class ReviewsController; def rescue_action(e) raise e end; end

class ReviewsControllerTest < Test::Unit::TestCase
  test_common_content_crud :name => 'Review', :form_vars => {:title => 'footapang', :description => 'bartapang', :main => 'oooo', :terms => 1}

  def setup
    @controller = ReviewsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
end
