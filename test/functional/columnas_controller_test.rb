# -*- encoding : utf-8 -*-
require 'test_helper'
require 'test_functional_content_helper'

class ColumnasControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Column', :form_vars => {
      :title => 'footapang',
      :description => "abracadabra",
      :main => 'hellouu',
  }, :root_terms => 1
end
