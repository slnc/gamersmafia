require File.dirname(__FILE__) + '/../../test_helper'
require 'cuenta/skins_controller'

# Re-raise errors caught by the controller.
class Cuenta::SkinsController; def rescue_action(e) raise e end; end

class Cuenta::SkinsControllerTest < Test::Unit::TestCase
  def setup
    @controller = Cuenta::SkinsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  # Replace this with your real tests.
  def test_index_should_work
    sym_login 1
    get :index
    assert_response :success
  end
  
  def test_should_create_factions_skin_if_everything_ok
    sym_login 1
    assert_count_increases(Skin) do 
      post :create, {:skin => {:name => 'foooskin', :type => 'ClansSkin', :intelliskin_header => fixture_file_upload('/files/buddha.jpg', 'image/jpeg')}}
      assert_response :redirect
    end
    @skin = Skin.find(:first, :order => 'id DESC')
    assert_not_nil @skin.intelliskin_header
  end
  
  def test_update_should_work
    test_should_create_factions_skin_if_everything_ok
    post :update, { :id => @skin.id, :skin => { :name => 'nuevo name'}}
    assert_response :redirect
    @skin.reload
    assert_equal 'nuevo name', @skin.name
  end
  
  def test_should_create_clans_skin_if_everything_ok
    sym_login 1
    assert_count_increases(Skin) do 
      post :create, {:skin => {:name => 'foooskin', :type => 'FactionsSkin'}}
      assert_response :redirect
    end
  end
  
  
  def test_should_edit
    Skin.find(1).send :setup_initial_zip
    sym_login 1
    get :edit, {:id => 1}
    assert_response :success
  end
  
  def test_should_delete_clans_skin_if_everything_ok
    sym_login 1
    assert_count_decreases(Skin) do 
      post :destroy, {:id => 1}
      assert_response :redirect
    end
  end

  
  def setup_clan_config_screens
    setup_clan_skin
    cp = ClansPortal.find(:first)
    @request.host = "#{cp.code}.#{App.domain}"
    sym_login 1
  end
  
  def test_cabecera
    setup_clan_config_screens
    get :cabecera, { :id => @s.id}
    assert_response :success
  end
  
  def test_organizacion
    setup_clan_config_screens
    get :organizacion, { :id => @s.id}
    assert_response :success
  end
  
  def test_modulos
    setup_clan_config_screens
    get :modulos, { :id => @s.id}
    assert_response :success
  end
  
  def test_colores
    setup_clan_config_screens
    get :colores, { :id => @s.id}
    assert_response :success
  end
  
  def test_texturas
    setup_clan_config_screens
    get :texturas, { :id => @s.id}
    assert_response :success
  end
  
  def test_otras_opciones
    setup_clan_config_screens
    get :otras_opciones, { :id => @s.id}
    assert_response :success
  end
  
  def test_do_modulos
    test_modulos
    params = {:id => @s.id, :skin => { :intelliskin => { :modules_left => %w(online tracker), :modules_right => %w(hits)} }}
    #Skins::Clans.available_modules.each do |mod|
    #params[:skin][:intelliskin][:modules][mod.to_s] = 1
    #end
    post :do_modulos, params
    assert_response :redirect
    @s = Skin.find(@s.id) # no hacer reload
    assert_equal 'online', @s.config[:intelliskin][:modules_left][0]
    assert_equal 'tracker', @s.config[:intelliskin][:modules_left][1]
    assert_equal 'hits', @s.config[:intelliskin][:modules_right][0]
    #Skins::Clans.available_modules.each do |mod|
    #assert @s.config[:intelliskin][:modules][mod] 
    #end
  end
  
  
  def test_do_cabecera
    test_cabecera
    post :do_cabecera, {:id => @s.id, :skin => { :intelliskin => {:header_height => '66'}, :intelliskin_header => fixture_file_upload('files/buddha.jpg', 'image/jpeg')}} 
    assert_response :redirect
    @s = Skin.find(@s.id) # no hacer reload    
    assert @s.intelliskin_header.include?('buddha.jpg')
    assert_equal '66', @s.config[:intelliskin][:header_height]
  end
  
  def test_do_otras_opciones
    test_cabecera
    post :do_otras_opciones, {:id => @s.id, :skin => { :intelliskin_favicon => fixture_file_upload('files/buddha.jpg', 'image/jpeg')}} 
    assert_response :redirect
    @s = Skin.find(@s.id) # no hacer reload    
    assert @s.intelliskin_favicon.include?('buddha.jpg') 
  end
  
  def test_do_organizacion
    test_organizacion
    post :do_organizacion, {:id => @s.id, :skin => { :intelliskin => {:page_width => '760'}}} 
    assert_response :redirect
    @s = Skin.find(@s.id) # no hacer reload    
    assert_equal '760', @s.config[:intelliskin][:page_width] 
  end
  
  def test_do_colores
    test_colores
    # TODO probar con todos los color gens
    
    post :do_colores, {:id => @s.id, :skin => { :intelliskin => {:color_gen => 'OnWhite', :OnWhite => {:color_gen_params => {:hue => '50'}}}}} 
    assert_response :redirect
    @s = Skin.find(@s.id) # no hacer reload    
    
    assert_equal 'OnWhite', @s.config[:intelliskin][:color_gen]
    assert_equal '50', @s.config[:intelliskin][:OnWhite][:color_gen_params][:hue]
  end
  
  def test_texturas_por_tipo
    test_texturas
    get :texturas_por_tipo, :id => 'body'
    assert_response :success
  end
  
  def test_config_textura
    test_texturas
    get :config_textura, :id => 'GrayscalePatternChecker'
    assert_response :success
  end
  
  def test_do_create_textura
    test_texturas
    assert_count_increases(SkinTexture) do
      post :do_create_textura, {:skin_texture => { :texture_id => 1, :skin_id => @s.id, :element => 'body', :user_config => {:color => '00ff00'}}}
    end
    assert_response :redirect
    @sk = SkinTexture.find(:first, :order => 'id desc')
    assert_equal '00ff00', @sk.user_config[:color]
  end
  
  def test_skin_textura
    test_do_create_textura
    get :skin_textura, :id => SkinTexture.find(:first, :order => 'id desc').id 
    assert_response :success
  end
  
  def test_update_skin_texture
    test_do_create_textura
    post :update_skin_texture, :id => SkinTexture.find(:first, :order => 'id desc').id, :user_config => @s.id  
  end
  
  def tesst_borrar_skin_textura
    test_do_create_textura
    assert_count_decreases(SkinTexture) do
      post :borrar_skin_textura, :id => SkinTexture.find(:first, :order => 'id desc').id
    end
    assert_response :redirect
  end
end
