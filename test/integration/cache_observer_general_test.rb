require 'test_helper'

class CacheObserverGeneralTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end
  
  def go_to_index
    get '/'
    assert_response :success
    assert_template 'home/index'
  end


  def teardown
    ActionController::Base.perform_caching             = false
  end
end
