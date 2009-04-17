require 'test_helper'

class SiteTest < ActiveSupport::TestCase
  HOW_MANY = 100
  def setup
    @controller = SiteController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    get :staff
  end
#  test "truth" do
    #elapsedSeconds = Benchmark::realtime do
      #Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/performance', 'anonymous_users')
      
    #end
#    assert elapsedSeconds < 8.0, "Actually took #{elapsedSeconds} seconds"
  #end
end
