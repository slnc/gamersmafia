require 'test_helper'

class Cuenta::SkinsControllerTest < ActionController::TestCase


  test "trying to use a deleted skin should work properly" do
      test_activate_my_own_skin_should_work
      post :destroy, :id => @skin.id
      assert_response :redirect

      assert Skin.find_by_id(@skin.id).nil?

      get :index
      assert_response :success
      assert @response.body.index("skins/default/")
  end

  test "activate my own skin should work" do
      test_should_create_factions_skin_if_everything_ok
      post :activate, :skin => @skin.id
      assert_response :redirect
      get :index
      assert_response :success
      assert @response.body.index("storage/skins/#{@skin.hid}/")
  end
  
  test "reset skin should work" do
      test_activate_my_own_skin_should_work
      post :activate, :skin => '-1'
      assert_response :redirect
      get :index
      assert_response :success
      assert @response.body.index("skins/default/")
  end
  # Replace this with your real tests.
  test "index_should_work" do
    sym_login 1
    get :index
    assert_response :success
  end
  
  test "should_create_factions_skin_if_everything_ok" do
    sym_login 1
    assert_count_increases(Skin) do 
      post :create, {:skin => {:name => 'foooskin', :type => 'ClansSkin', :intelliskin_header => fixture_file_upload('/files/buddha.jpg', 'image/jpeg')}}
      assert_response :redirect
    end
    @skin = Skin.find(:first, :order => 'id DESC')
    assert_not_nil @skin.intelliskin_header
  end
  
  test "update_should_work" do
    test_should_create_factions_skin_if_everything_ok
    post :update, { :id => @skin.id, :skin => { :name => 'nuevo name'}}
    assert_response :redirect
    @skin.reload
    assert_equal 'nuevo name', @skin.name
  end
  
  test "should_create_clans_skin_if_everything_ok" do
    sym_login 1
    assert_count_increases(Skin) do 
      post :create, {:skin => {:name => 'foooskin', :type => 'FactionsSkin'}}
      assert_response :redirect
    end
  end
  
  
  test "should_edit" do
    Skin.find(1).send :setup_initial_zip
    sym_login 1
    get :edit, {:id => 1}
    assert_response :success
  end
  
  test "should_delete_clans_skin_if_everything_ok" do
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
  
  test "cabecera" do
    setup_clan_config_screens
    get :cabecera, { :id => @s.id}
    assert_response :success
  end
  
  test "organizacion" do
    setup_clan_config_screens
    get :organizacion, { :id => @s.id}
    assert_response :success
  end
  
  test "modulos" do
    setup_clan_config_screens
    get :modulos, { :id => @s.id}
    assert_response :success
  end
  
  test "colores" do
    setup_clan_config_screens
    get :colores, { :id => @s.id}
    assert_response :success
  end
  
  test "texturas" do
    setup_clan_config_screens
    get :texturas, { :id => @s.id}
    assert_response :success
  end
  
  test "otras_opciones" do
    setup_clan_config_screens
    get :otras_opciones, { :id => @s.id}
    assert_response :success
  end
  
  test "do_modulos" do
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
  
  
  test "do_cabecera" do
    test_cabecera
    post :do_cabecera, {:id => @s.id, :skin => { :intelliskin => {:header_height => '66'}, :intelliskin_header => fixture_file_upload('files/buddha.jpg', 'image/jpeg')}} 
    assert_response :redirect
    @s = Skin.find(@s.id) # no hacer reload    
    assert @s.intelliskin_header.include?('buddha.jpg')
    assert_equal '66', @s.config[:intelliskin][:header_height]
  end
  
  test "do_otras_opciones" do
    test_cabecera
    post :do_otras_opciones, {:id => @s.id, :skin => { :intelliskin_favicon => fixture_file_upload('files/buddha.jpg', 'image/jpeg')}} 
    assert_response :redirect
    @s = Skin.find(@s.id) # no hacer reload    
    assert @s.intelliskin_favicon.include?('buddha.jpg') 
  end
  
  test "do_organizacion" do
    test_organizacion
    post :do_organizacion, {:id => @s.id, :skin => { :intelliskin => {:page_width => '760'}}} 
    assert_response :redirect
    @s = Skin.find(@s.id) # no hacer reload    
    assert_equal '760', @s.config[:intelliskin][:page_width] 
  end
  
  test "do_colores" do
    test_colores
    # TODO probar con todos los color gens
    
    post :do_colores, {:id => @s.id, :skin => { :intelliskin => {:color_gen => 'OnWhite', :OnWhite => {:color_gen_params => {:hue => '50'}}}}} 
    assert_response :redirect
    @s = Skin.find(@s.id) # no hacer reload    
    
    assert_equal 'OnWhite', @s.config[:intelliskin][:color_gen]
    assert_equal '50', @s.config[:intelliskin][:OnWhite][:color_gen_params][:hue]
  end
  
  test "texturas_por_tipo" do
    test_texturas
    get :texturas_por_tipo, :id => 'body'
    assert_response :success
  end
  
  test "config_textura" do
    test_texturas
    get :config_textura, :id => 'GrayscalePatternChecker'
    assert_response :success
  end
  
  test "do_create_textura" do
    test_texturas
    assert_count_increases(SkinTexture) do
      post :do_create_textura, {:skin_texture => { :texture_id => 1, :skin_id => @s.id, :element => 'body', :user_config => {:color => '00ff00'}}}
    end
    assert_response :redirect
    @sk = SkinTexture.find(:first, :order => 'id desc')
    assert_equal '00ff00', @sk.user_config[:color]
  end
  
  test "skin_textura" do
    test_do_create_textura
    get :skin_textura, :id => SkinTexture.find(:first, :order => 'id desc').id 
    assert_response :success
  end
  
  test "update_skin_texture" do
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
