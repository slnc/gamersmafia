# -*- encoding : utf-8 -*-
require 'test_helper'
require 'test_functional_content_helper'

class CuriosidadesControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Funthing', :form_vars => {:title => 'footapang', :description => 'bartapang', :main => 'http://batracios.com/'}
end
