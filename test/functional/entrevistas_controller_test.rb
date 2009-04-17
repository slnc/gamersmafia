require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'

class EntrevistasControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Interview', :form_vars => {:title => 'footapang', :description => 'bartapang', :main => 'aaa'}, :root_terms => 1


end
