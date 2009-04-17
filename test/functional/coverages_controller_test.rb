require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'
require 'coverages_controller'

# Re-raise errors caught by the controller.
class CoveragesController; def rescue_action(e) raise e end; end

class CoveragesControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Coverage', :form_vars => {:title => 'footapang', :description => 'bartapang', :event_id => 1}, :root_terms => 1


end
