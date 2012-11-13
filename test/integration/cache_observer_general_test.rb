# -*- encoding : utf-8 -*-
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

  test "should clear cache aportaciones after content is saved" do
    sym_login :superadmin, 'lalala'
    get '/miembros/superadmin'
    assert_response :success
    u = User.find_by_login!('superadmin')
    assert_cache_exists "#{Cache.user_base(u.id)}/profile/aportaciones"
    assert_difference('News.count') do
      post '/noticias/create', :news => {
        :title => 'noticia de ejemplo',
        :description => 'sumario de la noticia',
      },
      :root_terms => [1]
    end
    assert_response :redirect
    assert_cache_dont_exist "#{Cache.user_base(u.id)}/profile/aportaciones"
  end

  def teardown
    ActionController::Base.perform_caching = false
  end
end
