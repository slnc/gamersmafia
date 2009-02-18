require File.dirname(__FILE__) + '/../test_helper'
require 'cache_controller'

# Re-raise errors caught by the controller.
class CacheController; def rescue_action(e) raise e end; end

class ActionController::TestRequest
  attr_accessor :user_agent
end

class CacheControllerTest < Test::Unit::TestCase
  def setup
    @controller = CacheController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_thumbnails_with_valid_image
    full_file = "#{RAILS_ROOT}/public/cache/thumbnails/f/125x125/images/headers/tu_gustar_ficha_miembros.jpg"
    File.unlink(full_file) if File.exists?(full_file)
    get :thumbnails, { :mode => 'f', :dim => '125x125', :path => 'images/headers/tu_gustar_ficha_miembros.jpg' }
    assert_response :success
    assert File.exists?(full_file)
  end

  def test_thumbnails_with_valid_image_if_msie
    full_file = "#{RAILS_ROOT}/public/cache/thumbnails/f/125x125/images/headers/tu_gustar_ficha_miembros.jpg"
    File.unlink(full_file) if File.exists?(full_file)
    @request.user_agent = 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)'
    get :thumbnails, { :mode => 'f', :dim => '125x125', :path => 'images/headers/tu_gustar_ficha_miembros.jpg' }
    assert_response :success
    # assert 'image/jpeg', @response.content_type
    assert File.exists?(full_file)
  end

  def test_raises_404_if_invalid_image
    assert_raises(ActiveRecord::RecordNotFound) { 
      get :thumbnails, { :mode => 'f', :dim => '125x125', :path => 'abdulkabarahjmed.jpg' }
    }
  end
  
  def test_raises_404_if_invalid_image2
    assert_raises(ActiveRecord::RecordNotFound) { 
      get :thumbnails, { :mode => 'f', :dim => '125x125', :path => '' }
    }
  end
  
  def test_faction_users_ratios_should_work
    Faction.find(1).users<< User.find(1)
    get :faction_users_ratios, { :date => Time.now.strftime('%Y%m%d'), :faction_id => ['1.png'] }
    assert_response :redirect
    assert File.exists?("#{RAILS_ROOT}/public/cache/graphs/faction_users_ratios/#{Time.now.strftime('%Y%m%d')}/1.png")
  end
end
