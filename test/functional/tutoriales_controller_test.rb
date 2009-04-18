require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'

class TutorialesControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Tutorial', :form_vars => {:title => 'footapang', :description => 'bartapang', :main => 'aaa'}, :categories_terms => 19


end
