require 'test_helper'

class MiembrosControllerTest < ActionController::TestCase
  basic_test :index
  
  test "should_raise_404_if_user_not_found" do
    assert_raises(ActiveRecord::RecordNotFound) { get :member, :login => 'aaaaaaaaaaaaaabecedario_canónico' }
  end
  
  test "member" do
    get :member, :login => User.find(1).login
    assert_response :success
    assert_template 'member'
  end
  
  test "member_antiflood" do
    User.find(1).update_attributes(:antiflood_level => 1)
    test_member
  end
  
  test "member_should_redir_if_wrong_case" do
    get :member, :login => User.find(1).login.upcase
    assert_response 301
  end
  
  test "member_in_faction" do
    @request.host = 'ut.gamersmafia.com'
    test_member
  end
  
  test "member_in_platform" do
    @request.host = 'wii.gamersmafia.com'
    test_member
  end
  
  test "del_firma" do
    sym_login 1
    ps = ProfileSignature.new(:user_id => 1, :signer_user_id => 2, :signature => "hgolaaaa")
    assert ps.save, ps.errors.full_messages_html
    assert_count_decreases(ProfileSignature) do
      post :del_firma, :id => ps.id
      assert_response :success
    end
  end
  
  test "member_with_dot" do
    u = User.new({:login => 'dil.', :email => 'foo@goo.com', :state => User::ST_ACTIVE, :ipaddr => '0.0.0.0', :lastseen_on => Time.now})
    assert_equal true, u.save, u.errors.full_messages
    get :member, :login => 'dil.'
    assert_response :success
    assert_template 'member'
  end
  
  test "should_not_show_profile_signatures_page_if_user_has_no_profiles_signature_product" do
    assert_raises(ActiveRecord::RecordNotFound) { get :firmas, { :login => User.find(2).login } } # panzer no tiene
  end
  
  test "should_show_profile_signatures_page_if_user_has_profiles_signature_product" do
    get :firmas, { :login => User.find(1).login }
    assert_response :success
  end
  
  test "should_leave_new_signature" do
    sym_login 2
    @u1 = User.find(1)
    countsigs = @u1.profile_signatures_count
    post :update_signature, { :login => @u1.login, :profile_signature => { :signature => 'vaka' }}
    assert_response :redirect
    @u1.reload
    assert_equal countsigs + 1, @u1.profile_signatures_count
  end
  
  test "should_not_leave_new_signature_if_same_person" do
    sym_login 1
    @u1 = User.find(1)
    countsigs = @u1.profile_signatures_count
    assert_raises(AccessDenied) do
      post :update_signature, { :login => @u1.login, :profile_signature => { :signature => 'vaka' }}
    end
    @u1.reload
    assert_equal countsigs, @u1.profile_signatures_count
  end
  
  
  test "no_tengo_amigos" do
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
  
  test "should_update_existing_signature" do
    test_should_leave_new_signature
    countsigs = @u1.profile_signatures_count
    post :update_signature, { :login => @u1.login, :profile_signature => { :signature => 'vakaput' }}
    assert_response :redirect
    @u1.reload
    assert_equal countsigs, @u1.profile_signatures_count
    assert_equal 'vakaput', @u1.profile_signatures.find(:first, :order => 'updated_on DESC').signature
  end
  
  test "contenidos_tipo" do
   (Cms::contents_classes + [Blogentry]).each do |ctype|
      get :contenidos_tipo, { :login => User.find(1).login, :content_name => Cms.translate_content_name(ctype.name).titleize }
      assert_response :success
      assert_template 'contenidos_tipo'
    end
  end
  
  test "contenidos_should_work" do
    post :contenidos, :login => User.find(1).login
    assert_response :success
  end
  
  test "contenidos_tipo_incorrect_should_raise_404" do
    assert_raises(ActiveRecord::RecordNotFound) { get :contenidos_tipo, { :login => User.find(1).login, :content_name => 'noexiste' } }
  end
  
  test "buscar_should_redirect_if_no_search" do
    post :buscar
    assert_redirected_to '/miembros'
  end
  
  test "buscar_should_do_nothing_if_nonexistent_login_given" do
    post :buscar, :s => 'panzerzzzzzzzzzzzzz'
    assert_response :success
    assert_template 'buscar'
  end
  
  test "buscar_should_find_if_given_name" do
    post :buscar, :s => 'panzer'
    assert_response :success
    assert_template 'buscar'
    assert_not_nil @response.body =~ /"\/miembros\/panzer"/
  end
  
  test "buscar_por_guid_should_do_nothing_if_nonexistent_login_given" do
    post :buscar_por_guid, { :game_id => 1, :guid => 'panzerzzzzzzzzzzzzz' }
    assert_response :success
    assert_template 'buscar'
  end
  
  test "buscar_por_guid_should_find_if_given_guid" do
    post :buscar_por_guid, { :game_id => 1, :guid => '1234567890' }
    assert_response :success
    assert_template 'buscar'
    assert_not_nil @response.body =~ /"\/miembros\/superadmin"/
  end
  
  test "should_show_competicion" do
    get :competicion, :login => 'superadmin'
    assert_response :success
    assert_template 'competicion'
  end
  
  test "should_show_hardware" do
    get :hardware, :login => 'superadmin'
    assert_response :success
    assert_template 'hardware'
  end
  
  test "should_show_estadisticas" do
    get :estadisticas, :login => 'superadmin'
    assert_response :success
    assert_template 'estadisticas'
  end
  
  test "should_show_estadisticas_with_recent_user" do
    User.db_query("UPDATE users set created_on = now() where login = 'panzer'")
    get :estadisticas, :login => 'panzer'
    assert_response :success
    assert_template 'estadisticas'
  end
  
  test "should_show_amigos" do
    assert User.find_by_login('superadmin').friends_count > 0
    get :amigos, :login => 'superadmin'
    assert_response :success
    assert_template 'amigos'
  end
  
end
