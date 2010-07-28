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
      post '/noticias/create', :news => { :title => 'noticia de ejemplo', :description => 'sumario de la noticia'}, :root_terms => [1]
    end
    assert_response :redirect
    assert_cache_dont_exist "#{Cache.user_base(u.id)}/profile/aportaciones"
  end
  
  
  test "should clear users avatar cache after changing nick" do
    sym_login :superadmin, 'lalala'
    get '/'
    assert_response :success
    assert_cache_exists "/common/globalnavbar/#{1 % 1000}/1_avatar"
    assert User.find(1).update_attributes(:login => 'foobarbaz')
    assert_cache_dont_exist "/common/globalnavbar/#{1 % 1000}/1_avatar"
    
  end
  
  test "should clear skins cache on skin's public attribute change" do
    sym_login :superadmin, 'lalala' 
    get '/'
    assert_response :success
    assert_cache_exists '/common/layout/skins'
    s = Skin.find(1)
    assert s.update_attributes(:is_public => false)
    assert_cache_dont_exist '/common/layout/skins'
    get '/'
    assert_response :success
    assert_cache_exists '/common/layout/skins'
    assert s.update_attributes(:is_public => true)
    assert_cache_dont_exist '/common/layout/skins'
  end
  
  def teardown
    ActionController::Base.perform_caching             = false
  end
end
