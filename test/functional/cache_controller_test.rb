# -*- encoding : utf-8 -*-
require 'test_helper'

class ActionController::TestRequest
  attr_accessor :user_agent
end

class CacheControllerTest < ActionController::TestCase


  test "thumbnails with invalid size" do
    %w(0x0 ax0 -1x-5 100000x50).each do |wrongdim|
      assert_raises(ActiveRecord::RecordNotFound) do
        get :thumbnails, { :mode => 'f', :dim => wrongdim, :path => 'images/golpe_de_estado.jpg' }
      end
    end
  end

  test "thumbnails_with_valid_image" do
    full_file = "#{Rails.root}/public/cache/thumbnails/f/125x125/images/golpe_de_estado.jpg"
    File.unlink(full_file) if File.exists?(full_file)
    get :thumbnails, { :mode => 'f', :dim => '125x125', :path => 'images/golpe_de_estado.jpg' }
    assert_response :success
    assert File.exists?(full_file)
  end

  test "thumbnails_with_valid_image_if_msie" do
    full_file = "#{Rails.root}/public/cache/thumbnails/f/125x125/images/golpe_de_estado.jpg"
    File.unlink(full_file) if File.exists?(full_file)
    @request.user_agent = 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)'
    get :thumbnails, { :mode => 'f', :dim => '125x125', :path => 'images/golpe_de_estado.jpg' }
    assert_response :success
    # assert 'image/jpeg', @response.content_type
    assert File.exists?(full_file)
  end

  test "raises_404_if_invalid_image" do
    assert_raises(ActiveRecord::RecordNotFound) {
      get :thumbnails, { :mode => 'f', :dim => '125x125', :path => 'abdulkabarahjmed.jpg' }
    }
  end

  test "raises_404_if_invalid_image2" do
    assert_raises(ActiveRecord::RecordNotFound) {
      get :thumbnails, { :mode => 'f', :dim => '125x125', :path => '' }
    }
  end

  test "faction_users_ratios_should_work" do
    Faction.find(1).users<< User.find(1)
    get :faction_users_ratios,
        {:date => Time.now.strftime('%Y%m%d'),
         :faction_id => ['1.png']
        }
    assert_response :redirect
    assert File.exists?("#{Rails.root}/public/cache/graphs/faction_users_ratios/#{Time.now.strftime('%Y%m%d')}/1.png")
  end
end
