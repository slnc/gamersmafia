require File.dirname(__FILE__) + '/../test_helper'
require 'miembros_controller'

# Re-raise errors caught by the controller.
class MiembrosController; def rescue_action(e) raise e end; end

class MiembrosControllerTest < Test::Unit::TestCase
  def setup
    @controller = MiembrosController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  basic_test :index
  
  def test_should_raise_404_if_user_not_found
    assert_raises(ActiveRecord::RecordNotFound) { get :member, :login => 'aaaaaaaaaaaaaabecedario_canónico' }
  end
  
  def test_member
    get :member, :login => User.find(1).login
    assert_response :success
    assert_template 'member'
  end
  
  def test_member_antiflood
    User.find(1).update_attributes(:antiflood_level => 1)
    test_member
  end
  
  def test_member_should_redir_if_wrong_case
    get :member, :login => User.find(1).login.upcase
    assert_response :redirect
    assert @response.headers['Status'].starts_with?('301 ')
  end
  
  def test_member_in_faction
    @request.host = 'ut.gamersmafia.com'
    test_member
  end
  
  def test_member_in_platform
    @request.host = 'wii.gamersmafia.com'
    test_member
  end
  
  def test_del_firma
    sym_login 1
    ps = ProfileSignature.new(:user_id => 1, :signer_user_id => 2, :signature => "hgolaaaa")
    assert ps.save, ps.errors.full_messages_html
    assert_count_decreases(ProfileSignature) do
      post :del_firma, :id => ps.id
      assert_response :success
    end
  end
  
  def test_member_with_dot
    u = User.new({:login => 'dil.', :email => 'foo@goo.com', :state => User::ST_ACTIVE, :ipaddr => '0.0.0.0', :lastseen_on => Time.now})
    assert_equal true, u.save, u.errors.full_messages
    get :member, :login => 'dil.'
    assert_response :success
    assert_template 'member'
  end
  
  def test_should_not_show_profile_signatures_page_if_user_has_no_profiles_signature_product
    assert_raises(ActiveRecord::RecordNotFound) { get :firmas, { :login => User.find(2).login } } # panzer no tiene
  end
  
  def test_should_show_profile_signatures_page_if_user_has_profiles_signature_product
    get :firmas, { :login => User.find(1).login }
    assert_response :success
  end
  
  def test_should_leave_new_signature
    sym_login 2
    @u1 = User.find(1)
    countsigs = @u1.profile_signatures_count
    post :update_signature, { :login => @u1.login, :profile_signature => { :signature => 'vaka' }}
    assert_response :redirect
    @u1.reload
    assert_equal countsigs + 1, @u1.profile_signatures_count
  end
  
  def test_no_tengo_amigos
    sym_login 1
    u1 = User.find_by_login('mrcheater')
    friends_count = u1.friends_count
    assert_equal 0, u1.friends_count
    deliv = ActionMailer::Base.deliveries.size
    assert_count_increases(Friendship) do
      get :no_tengo_amigos, { :login => 'panzer' }
      assert_response :redirect
    end
    #puts ActionMailer::Base.deliveries[ActionMailer::Base.deliveries.size - 2]
    #puts ActionMailer::Base.deliveries.last
    assert_equal deliv + 1, ActionMailer::Base.deliveries.size
  end
  
  def test_should_update_existing_signature
    test_should_leave_new_signature
    countsigs = @u1.profile_signatures_count
    post :update_signature, { :login => @u1.login, :profile_signature => { :signature => 'vakaput' }}
    assert_response :redirect
    @u1.reload
    assert_equal countsigs, @u1.profile_signatures_count
    assert_equal 'vakaput', @u1.profile_signatures.find(:first, :order => 'updated_on DESC').signature
  end
  
  def test_contenidos_tipo
   (Cms::contents_classes + [Blogentry]).each do |ctype|
      get :contenidos_tipo, { :login => User.find(1).login, :content_name => Cms.translate_content_name(ctype.name).titleize }
      assert_response :success
      assert_template 'contenidos_tipo'
    end
  end
  
  def test_contenidos_should_work
    post :contenidos, :login => User.find(1).login
    assert_response :success
  end
  
  def test_contenidos_tipo_incorrect_should_raise_404
    assert_raises(ActiveRecord::RecordNotFound) { get :contenidos_tipo, { :login => User.find(1).login, :content_name => 'noexiste' } }
  end
  
  def test_buscar_should_redirect_if_no_search
    post :buscar
    assert_redirected_to '/miembros'
  end
  
  def test_buscar_should_do_nothing_if_nonexistent_login_given
    post :buscar, :s => 'panzerzzzzzzzzzzzzz'
    assert_response :success
    assert_template 'buscar'
  end
  
  def test_buscar_should_find_if_given_name
    post :buscar, :s => 'panzer'
    assert_response :success
    assert_template 'buscar'
    assert_not_nil @response.body =~ /"\/miembros\/panzer"/
  end
  
  def test_buscar_por_guid_should_do_nothing_if_nonexistent_login_given
    post :buscar_por_guid, { :game_id => 1, :guid => 'panzerzzzzzzzzzzzzz' }
    assert_response :success
    assert_template 'buscar'
  end
  
  def test_buscar_por_guid_should_find_if_given_guid
    post :buscar_por_guid, { :game_id => 1, :guid => '1234567890' }
    assert_response :success
    assert_template 'buscar'
    assert_not_nil @response.body =~ /"\/miembros\/superadmin"/
  end
  
  def test_should_show_competicion
    get :competicion, :login => 'superadmin'
    assert_response :success
    assert_template 'competicion'
  end
  
  def test_should_show_hardware
    get :hardware, :login => 'superadmin'
    assert_response :success
    assert_template 'hardware'
  end
  
  def test_should_show_estadisticas
    get :estadisticas, :login => 'superadmin'
    assert_response :success
    assert_template 'estadisticas'
  end
  
  def test_should_show_estadisticas_with_recent_user
    User.db_query("UPDATE users set created_on = now() where login = 'panzer'")
    get :estadisticas, :login => 'panzer'
    assert_response :success
    assert_template 'estadisticas'
  end
  
  def test_should_show_amigos
    assert User.find_by_login('superadmin').friends_count > 0
    get :amigos, :login => 'superadmin'
    assert_response :success
    assert_template 'amigos'
  end
  
end
