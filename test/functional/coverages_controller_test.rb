require 'test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'

class CoveragesControllerTest < ActionController::TestCase
  test_common_content_crud(
      :name => 'Coverage',
      :form_vars => {
          :title => 'footapang',
          :description => 'bartapang',
          :event_id => 1,
      })
end
