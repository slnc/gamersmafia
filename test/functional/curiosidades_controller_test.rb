require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'

class CuriosidadesControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Funthing', :form_vars => {:title => 'footapang', :description => 'bartapang', :main => 'http://batracios.com/'}


end
