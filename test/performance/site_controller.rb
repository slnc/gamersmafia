require 'test_helper'
require 'site_controller'

class SiteTest < ActiveSupport::TestCase
  HOW_MANY = 100
  def setup
    @controller = SiteController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    get :staff
  end
#  def test_truth
    #elapsedSeconds = Benchmark::realtime do
      #Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/performance', 'anonymous_users')
      
    #end
#    assert elapsedSeconds < 8.0, "Actually took #{elapsedSeconds} seconds"
  #end
end
