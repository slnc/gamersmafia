require File.dirname(__FILE__) + '/../test_helper'

class TemasControllerTest < ActionController::TestCase
  basic_test :index
  
  def test_tema
    # bazar.children.create(:code => 'anime', :name => 'Anime')
    get :tema, :code => 'anime'
    assert_response :success
  end
end
