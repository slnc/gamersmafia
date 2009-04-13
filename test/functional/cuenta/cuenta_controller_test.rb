require File.dirname(__FILE__) + '/../../test_helper'
require 'cuenta/cuenta_controller'

# Re-raise errors caught by the controller.
class Cuenta::CuentaController; def rescue_action(e) raise e end; end

class Cuenta::CuentaControllerTest < Test::Unit::TestCase
  
  def setup
    @controller = Cuenta::CuentaController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end
  
  def test_mis_permisos_should_work
    sym_login 2
    %w(Don ManoDerecha Boss Underboss Sicario Moderator Advertiser GroupMember GroupAdministrator CompetitionAdmin CompetitionSupervisor).each do |r|
      @ur = UsersRole.new(:user_id => 2, :role => r, :role_data => '1')
      assert @ur.save
    end
    
    @ur = UsersRole.new(:user_id => 2, :role => 'Editor', :role_data => {:content_type_id => 1, :faction_id => 1}.to_yaml)
    assert @ur.save
    
    get :mis_permisos
    assert_response :success
  end
  
  def test_del_role_should_work
    test_mis_permisos_should_work
    assert_count_decreases(UsersRole) do
      post :del_role, :id => @ur.id
    end
    assert_response :success
  end
  
  def test_del_role_other_shouldnt_work
    test_mis_permisos_should_work
    sym_login 1    
    assert_raises(ActiveRecord::RecordNotFound) {  post :del_role, :id => @ur.id }
  end
  
  def test_add_quicklink
    sym_login 2
    u2 = User.find(2)
    post :add_quicklink, :code => 'ut', :link => 'http://ut.gamersmafia.com/'
    assert_response :success
    qlinks = u2.pref_quicklinks
    assert qlinks[0][:code] == 'ut'
  end
  
  def test_del_quicklink
    sym_login 2
    u2 = User.find(2)
    orig_qlinks = u2.pref_quicklinks.size
    test_add_quicklink
    post :del_quicklink, :code => 'ut'
    assert_response :success
    u2.reload
    assert_equal orig_qlinks - 1, u2.pref_quicklinks.size
  end
  
  def test_add_user_forum
    sym_login 2
    u2 = User.find(2)
    post :add_user_forum, :id => '1'
    assert_response :success
    ufs = u2.pref_user_forums
    assert_equal 1, ufs[0][0]
  end
  
  def test_del_user_forum
    sym_login 2
    u2 = User.find(2)
    test_add_user_forum
    post :del_user_forum, :id => 1
    assert_response :success
    ufs = u2.pref_user_forums
    assert_equal 0, ufs[0].size
    assert_equal 0, ufs[1].size
  end
  
  def test_update_user_forums_order
    sym_login 2
    u2 = User.find(2)
    post :update_user_forums_order, :user_id => 1, :buckets1 => ['1'], :buckets2 => ['2', '3']
    assert_response :success
    ufs = u2.pref_user_forums
    assert_equal 3, ufs.size
    assert_equal 1, ufs[0][0]
    assert_equal 2, ufs[1][0]
    assert_equal 3, ufs[1][1]
  end
  
  
  
  def test_should_resurrect_resurrectable_user
    u2 = User.find(2)
    u2.lastseen_on = 4.months.ago
    u2.state = User::ST_ZOMBIE
    u2.save
    post :resurrect, {:login => 'panzer'}, {:user => 1}
    assert_response :success
    assert_template 'resurrect'
    u2.reload
    assert_equal 1, u2.resurrected_by_user_id
  end
  
  def test_should_login_valid_user
    u1 = User.find(1)
    one_month_ago = 1.month.ago
    u1.lastseen_on = one_month_ago
    u1.save
    post :do_login, :login => 'superadmin', :password => 'lalala'
    assert_redirected_to '/'
    assert_not_nil(session[:user])
    assert_equal session[:user], User.find_by_login('superadmin').id
    u1.reload
    assert_equal one_month_ago.to_i, u1.lastseen_on.to_i
  end
  
  def test_should_not_login_user_in_nonlogin_state
    u1 = User.find(1)
     (User::HSTATES - User::STATES_CAN_LOGIN).each do |invalid_state|
      u1.state = invalid_state
      assert_equal true, u1.save
      post :do_login, :login => 'superadmin', :password => 'lalala'
      assert_response :success
      assert_nil(session[:user])
    end
  end
  
  def test_should_not_ping_in_nonlogin_state
    u1 = User.find(1)
    User::STATES_CANNOT_LOGIN.each do |invalid_state|
      u1.state = invalid_state
      assert_equal true, u1.save
      get :index, {}, {:user => u1.id}
      assert_redirected_to '/cuenta/login'
      assert_nil session[:user]
    end
  end
  
  def test_should_not_login_with_unconfirmed_user
    post :do_login, :login => 'unconfirmed_user', :password => 'lelele'
    assert_response :success
    assert_template 'login'
    assert_nil session[:user]
  end
  
  def test_should_not_login_with_banned_account
    post :do_login, :login => 'banned_user', :password => 'lelele'
    assert_response :success
    assert_template 'login'
    assert_nil session[:user]
  end
  
  def test_should_not_login_with_disabled_account
    post :do_login, :login => 'disabled_user', :password => 'lelele'
    assert_response :success
    assert_template 'login'
    assert_nil session[:user]
  end
  
  def test_should_redirect_if_login_without_form
    post :do_login
    assert_redirected_to '/cuenta/login'
    assert_nil(session[:user])
  end
  
  def test_should_redirect_if_create_without_form
    post :create
    assert_redirected_to '/cuenta/alta'
    assert_nil(session[:user])
  end
  
  def test_should_not_create_user_if_login_is_invalid
    post :create, :user => { :login => '' }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
    
    post :create, :user => { :login => '")!="dmk1ionloº¡L-_:*^,' }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end
  
  def test_should_not_create_user_if_passwords_dont_match
    post :create, :user => { :login => 'chindasvinto', :password => 'jauja', :password_confirmation=> 'marauja' }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end
  
  def test_should_not_create_user_if_password_length_is_too_short
    post :create, :user => { :login => 'chindasvinto', :password => 'jau', :password_confirmation=> 'jau' }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end
  
  def test_should_not_create_if_login_is_duplicated_ignoring_case
    post :create, :user => { :login => 'superadmin', :password => 'marauja', :password_confirmation => 'marauja', :email => 'lala@lala.com' }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end
  
  def test_should_not_create_if_email_is_duplicated_ignoring_case
    post :create, :user => { :login => 'superadmin', :password => 'marauja', :password_confirmation => 'marauja', :email => 'superadmin@GAMERSMAFIA.com' }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end
  
  def test_should_not_create_if_email_is_invalid
    post :create, :user => { :login => 'chindasvinto', :password => 'marauja', :password_confirmation => 'marauja', :email => 'tupmuamad@jaja.ñ!jeje' }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end
  
  def test_should_not_create_if_email_domain_is_banned
    dom = User::BANNED_DOMAINS[0]
    post :create, :user => { :login => 'chindasvinto', :password => 'marauja', :password_confirmation => 'marauja', :email => "tupmuamad@#{dom}" }
    assert_template 'cuenta/cuenta/alta'
    assert_nil(session[:user])
  end
  
  def test_should_create_user_if_everything_is_valid
    post :create, :user => { :login => 'chindasvinto', :password => 'marauja', :password_confirmation => 'marauja', :email => 'tupmuamad@jaja.com' }
    assert_redirected_to "/cuenta/confirmar?em=tupmuamad@jaja.com"
    @u = User.find_by_login('chindasvinto')
    assert_not_nil @u
    assert_equal 'chindasvinto', @u.login
    assert_equal Digest::MD5.hexdigest('marauja'), @u.password
    assert_equal User::ST_UNCONFIRMED, @u.state
    # assert session[:user].kind_of?(Fixnum)
  end
  
  def test_should_create_second_account_from_same_ip
    test_should_create_user_if_everything_is_valid
    
    assert_count_increases(SlogEntry) do    
      post :create, :user => { :login => 'chindasvinto2', :password => 'marauja', :password_confirmation => 'marauja', :email => 'tupmuamad2@jaja.com' }
    end
    
    assert_redirected_to "/cuenta/confirmar?em=tupmuamad2@jaja.com"
    @u2 = User.find_by_login('chindasvinto2')
    assert_not_nil @u2
    assert_equal 'chindasvinto2', @u2.login
    assert_equal Digest::MD5.hexdigest('marauja'), @u2.password
    assert_equal User::ST_UNCONFIRMED, @u2.state
  end
  
  def test_should_not_create_user_if_ip_banned
    assert_count_increases(IpBan) { IpBan.create({:ip => '0.0.0.0', :user_id => 1}) }
    
    post :create, {:user => { :login => 'chindasvinto', :password => 'marauja', :password_confirmation => 'marauja', :email => 'tupmuamad@jaja.com' }}
    # Para un usuario con ip baneada no le decimos que está baneado, que se quede esperando el email
    assert_redirected_to '/cuenta/confirmar'
    @u = User.find_by_login('chindasvinto')
    assert_nil @u
  end
  
  def test_should_properly_acknowledge_referer
    panzer = User.find_by_login('panzer')
    mails_sent = ActionMailer::Base.deliveries.size
    post :create, :user => { :login => 'chindasvinto', :password => 'marauja', :password_confirmation => 'marauja', :email => 'tupmuamad@jaja.com'},
    :referer => 'panzer'
    u = User.find_by_login('chindasvinto')
    assert_equal panzer.id, u.referer_user_id
    assert_equal mails_sent + 1, ActionMailer::Base.deliveries.size # el email de confirmación de creación de cuenta
    assert_equal u.email, ActionMailer::Base.deliveries.at(-1).to[0]
    
    # now we confirm
    mails_sent = ActionMailer::Base.deliveries.size
    fp = panzer.faith_points
    post :do_confirmar, {:k => u.validkey, :email => u.email}
    panzer = User.find_by_login('panzer')
    assert_equal Faith::FPS_ACTIONS['registration'] + fp, panzer.faith_points
    assert_equal mails_sent + 2, ActionMailer::Base.deliveries.size # 2 por el email de welcome y el de aviso de referer, si añadimos uno más habrá que hacer una búsqueda para ver cuáles se mandan y cuáles no
    assert_equal panzer.email, ActionMailer::Base.deliveries.at(-2).to[0] # esto depende del orden en el controller
  end
  
  def test_should_send_confirmation_email_after_creating_account
    num_deliveries = ActionMailer::Base.deliveries.size
    test_should_create_user_if_everything_is_valid
    assert_equal num_deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  def test_should_send_welcome_email_after_confirming_account
    test_should_create_user_if_everything_is_valid
    num_deliveries = ActionMailer::Base.deliveries.size
    post :do_confirmar, {:k => @u.validkey, :email => @u.email}
    assert_redirected_to '/cuenta'
    assert_equal User::ST_SHADOW, User.find_by_validkey(@u.validkey).state
    assert_equal num_deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  #def test_should_redirect_to_login_if_anonymous_tries_to_access_profile_settings
  #  get :preferencias
  #  assert_response :redirect
  #  assert_redirected_to '/cuenta/login'
  #end
  
  #def test_should_redirect_to_login_if_anonymous_tries_to_save_settings
  #  post :guardar_preferencias
  #  assert_response :redirect
  #  assert_redirected_to '/cuenta/login'
  #end
  
  #  def test_should_save_settings_if_logged_in_and_correct_settings
  #    test_should_login_valid_user
  #    get :preferencias
  #    assert_response :success
  #    post :guardar_preferencias, :user => { :name => 'Pepito', :avatar => fixture_file_upload('/files/avatar_pepito.png', 'image/png'), :description => 'soy pro' }
  #    assert_response :redirect
  #    assert_redirected_to '/cuenta/'
  #    u = User.find(session[:user])
  #    assert_equal 'Pepito', u.name
  #    assert_equal 'storage/users/0000/001_avatar_pepito.png', u.avatar, "do: #{@controller.user.avatar}"
  #    assert_equal 'soy pro', u.description
  #    File.unlink("#{RAILS_ROOT}/public/#{u.avatar}") # TODO debería hacerlo el modelo al destruirlo y deberíamos destruirlo, no?
  #  end
  
  
  # TODO test que solo pasen los params que deben pasar
  # TODO añadir tests para cambio de settings, baja de una cuenta y logout
  
  def logout
    get :logout, {}, {:user => 1}
    assert_redirected_to '/'
    # TODO necesitamos integration testing para confirmar que logout funciona
  end
  
  # TODO test método GET 
  def test_should_not_autologin_if_invalid_client_cookie
    @request.cookies['ak'] = CGI::Cookie.new('autologin', 'foobar')    
    get :login
    assert_response :success
    assert_nil session[:user]
  end
  
  def test_should_not_autologin_if_client_cookie_non_existant_in_db
    akey = AutologinKey.find_by_key('05e3ab2d90b022d7bf1b3782dc0fd2e2aa7cc926')
    akey.destroy if akey
    @request.cookies['ak'] = CGI::Cookie.new('autologin', '05e3ab2d90b022d7bf1b3782dc0fd2e2aa7cc926')
    get :login
    assert_response :success
    assert_nil session[:user]
  end
  
  #def test_should_not_autologin_if_client_cookie_has_expired
  #end
  
  def test_should_autologin_and_redirect_if_sending_validkey_as_param
    get :login, { :vk => User.find(1).validkey }
    assert_response :redirect
    # assert_redirected_to
    assert !(/\?vk=([a-f0-9]{32})/ =~ @response.redirected_to)
    assert_not_nil session[:user]
    assert_equal 1, session[:user]
  end
  
  def test_should_redirect_if_authed_and_sending_validkey_as_param
    sym_login 1 
    test_should_autologin_and_redirect_if_sending_validkey_as_param
  end
  
  def test_should_autologin_if_client_cookie_is_set_and_exists_in_db
    k = '05e3ab2d90b022d7bf1b3782dc0fd2e2aa7cc926'
    akey = AutologinKey.find_by_key(k)
    akey = AutologinKey.create({:key => k, :user_id => 1, :lastused_on => Time.now}) if akey.nil?
    @request.cookies['ak'] = CGI::Cookie.new('autologin', k)
    get :login
    assert_response :redirect
    assert_not_nil session[:user]
    assert_equal 1, session[:user]
  end
  
  def test_should_not_autologin_with_unconfirmed_user
    test_should_autologin_if_client_cookie_is_set_and_exists_in_db
    u = User.find(1)
    u.state = User::ST_UNCONFIRMED
    u.save
    get :login
    assert_redirected_to '/cuenta/login'
    assert_nil session[:user]
  end
  
  def test_should_not_autologin_with_banned_user
    test_should_autologin_if_client_cookie_is_set_and_exists_in_db
    u = User.find(1)
    u.state = User::ST_BANNED
    assert_equal true, u.save, u.errors
    get :index
    assert_redirected_to '/cuenta/login'
    assert_nil session[:user]
  end
  
  def test_should_not_autologin_with_disabled_user
    test_should_autologin_if_client_cookie_is_set_and_exists_in_db
    u = User.find(1)
    u.state = User::ST_DISABLED
    u.save
    get :index
    assert_redirected_to '/cuenta/login'
    assert_nil session[:user]
  end
  
  def test_should_logout_active_user_if_just_banned
    test_should_autologin_if_client_cookie_is_set_and_exists_in_db
    u = User.find(1)
    u.state = User::ST_BANNED
    u.save
    get :index, {}, {:user => 1}
    assert_redirected_to'/cuenta/login'
    assert_nil session[:user]
  end
  
  def test_should_touch_if_autologged_in
    u = User.find(1)
    u.lastseen_on = 1.day.ago
    assert_equal true, u.save
    test_should_autologin_if_client_cookie_is_set_and_exists_in_db
    u.reload
    assert u.lastseen_on.to_i > 5.seconds.ago.to_i # hacemos esto porque suele
    # haber discrepancias de algunos segundos entre tiempo postgres y tiempo ruby
    # (probablemente por redondeos)
    # nota: pasamos a i porque hay discrepancia de milisegundos entre los tiempos de postgresql y los tiempos de ruby
  end
  
  def test_should_confirm_new_account_if_valid_confirm_key
    test_should_create_user_if_everything_is_valid
    post :do_confirmar, {:k => @u.validkey, :email => @u.email}
    assert_redirected_to '/cuenta'
    assert_equal User::ST_SHADOW, User.find_by_validkey(@u.validkey).state
  end
  
  def test_should_confirm_new_account_if_valid_confirm_key_but_with_extra_spaces
    test_should_create_user_if_everything_is_valid
    post :do_confirmar, {:k => " #{@u.validkey} ", :email => @u.email}
    assert_redirected_to '/cuenta'
    assert_equal User::ST_SHADOW, User.find_by_validkey(@u.validkey).state
  end
  
  def test_should_not_confirm_new_account_if_invalid_confirm_key
    test_should_create_user_if_everything_is_valid
    post :do_confirmar, {:k => 'bailar_el_chachacha', :email => @u.email}
    assert_response :success
    assert_template 'cuenta/cuenta/confirmar'
    u = User.find_by_login('chindasvinto')
    assert_equal User::ST_UNCONFIRMED, u.state
  end
  
  def test_should_send_reset_email_if_valid_login_or_email
    num_deliveries = ActionMailer::Base.deliveries.size
    post :do_olvide_clave, {:login => 'superadmin'}
    assert_equal num_deliveries + 1, ActionMailer::Base.deliveries.size
    assert_template 'cuenta/cuenta/do_olvide_clave'
    
    post :do_olvide_clave, {:email => 'superadmin@gamersmafia.com'}
    assert_equal num_deliveries + 2, ActionMailer::Base.deliveries.size
    assert_template 'cuenta/cuenta/do_olvide_clave'
    
    post :do_olvide_clave, {:email => 'SUPERADMIN@GAMERSMAFIA.COM'}
    assert_equal num_deliveries + 3, ActionMailer::Base.deliveries.size
    assert_template 'cuenta/cuenta/do_olvide_clave'
  end
  
  def test_should_not_send_reset_email_if_invalid_login_or_email
    num_deliveries = ActionMailer::Base.deliveries.size
    
    post :do_olvide_clave, {:login => 'superadminaaa'}
    assert_redirected_to :action => :olvide_clave
    assert_equal num_deliveries, ActionMailer::Base.deliveries.size
    
    post :do_olvide_clave, {:email => 'superadminaaaa@gamersmafia.com'}
    assert_redirected_to :action => :olvide_clave
    assert_equal num_deliveries, ActionMailer::Base.deliveries.size
    # assert_template 'cuenta/cuenta/olvide_clave'
  end
  
  def test_should_not_send_reset_email_after_three_times_in_5_mins
    num_deliveries = ActionMailer::Base.deliveries.size
    test_should_send_reset_email_if_valid_login_or_email
    assert_equal num_deliveries + 3, ActionMailer::Base.deliveries.size
    
    num_deliveries = ActionMailer::Base.deliveries.size
    post :do_olvide_clave, {:email => 'superadmin@gamersmafia.com'}
    assert_equal num_deliveries, ActionMailer::Base.deliveries.size
    assert_redirected_to :action => :olvide_clave
  end
  
  def test_should_send_reset_email_after_two_times_and_more_than_5_mins
    num_deliveries = ActionMailer::Base.deliveries.size
    test_should_send_reset_email_if_valid_login_or_email
    assert_equal num_deliveries + 3, ActionMailer::Base.deliveries.size
    User.db_query("UPDATE ip_passwords_resets_requests SET created_on = now() - '1 year'::interval")
    test_should_send_reset_email_if_valid_login_or_email
  end
  
  def test_should_allow_to_reset_if_valid_reset_key
    test_should_send_reset_email_if_valid_login_or_email
    u = User.find_by_login('superadmin')
    get :reset, {:k => u.validkey, :login => u.login}
    assert_response :success
    assert_template 'cuenta/cuenta/reset'
  end
  
  def test_should_reset_if_valid_key
    test_should_send_reset_email_if_valid_login_or_email
    u = User.find_by_login('superadmin')
    post :do_reset, {:k => u.validkey, :login => u.login, :password => 'brahman', :password_confirmation => 'brahman'}
    assert_redirected_to '/cuenta'
    u = User.find_by_login('superadmin')
    assert_equal Digest::MD5.hexdigest('brahman'), u.password
  end
  
  def test_should_not_reset_if_valid_key_but_invalid_passwords
    test_should_send_reset_email_if_valid_login_or_email
    u = User.find_by_login('superadmin')
    post :do_reset, {:k => u.validkey, :login => u.login, :password => 'brahman', :password_confirmation => 'brahmanBAD'}
    assert_response :success
    assert_template 'cuenta/cuenta/reset'
    u = User.find_by_login('superadmin')
    assert(Digest::MD5.hexdigest('brahman') != u.password)
  end
  
  def test_should_not_reset_if_invalid_key
    test_should_send_reset_email_if_valid_login_or_email
    u = User.find_by_login('superadmin')
    post :do_reset, {:k => 'aaaa', :login => u.login, :password => 'brahman', :password_confirmation => 'brahman'}
    assert_response :success
    assert_template 'cuenta/cuenta/olvide_clave'
    u = User.find_by_login('superadmin')
    assert(Digest::MD5.hexdigest('brahman') != u.password)
  end
  
  def test_should_update_newemail_if_given
    u = User.find(1)
    sym_login 1
    post :update_configuration, {:user => { :newemail => 'superadmin2@example.com' } }
    assert_response :redirect
    u.reload
    assert_equal 'superadmin2@example.com', u.newemail
  end
  
  
  def test_should_show_mis_borradores
    sym_login 1
    get :mis_borradores
    assert_response :success
  end
  
  def test_should_show_estadisticas
    sym_login 1
    get :estadisticas
    assert_response :success
  end
  
  def test_should_show_estadisticas_and_not_reset
    u = User.find(1)
    faith_points = u.faith_points
    sym_login 1
    get :estadisticas
    assert_response :success
    u.reload
    assert_equal faith_points, u.faith_points
  end
  
  def test_should_show_estadisticas_hits
    sym_login 1
    get :estadisticas_hits
    assert_response :success
  end
  
  def test_should_show_estadisticas_registros
    sym_login 1
    get :estadisticas_registros
    assert_response :success
  end
  
  def test_should_update_profile_with_youtube_in_description
    sym_login 1
    u = User.find(1)
    youtube_embed = '<object width="425" height="350"><param name="movie" value="http://www.youtube.com/v/2Iw1uEVaQpA"></param><param name="wmode" value="transparent"></param><embed src="http://www.youtube.com/v/2Iw1uEVaQpA" type="application/x-shockwave-flash" wmode="transparent" width="425" height="350"></embed></object>'
    youtube_expec = '<object height="350" width="425"><param name="movie" value="http://www.youtube.com/v/2Iw1uEVaQpA"></param><param name="wmode" value="transparent"></param><embed type="application/x-shockwave-flash" src="http://www.youtube.com/v/2Iw1uEVaQpA" height="350" wmode="transparent" width="425"></embed></object>'
    h = HashWithIndifferentAccess.new(u.attributes.merge({:description => youtube_embed}))
    last = u.profile_last_updated_on
    assert_nil last
    post :update_profile, { :post => h, :user => h }
    assert_response :redirect
    u.reload
    assert u.profile_last_updated_on >= 1.minute.ago
    assert_equal youtube_expec, u.description
  end
  
  def test_should_save_tracker_config
    sym_login 1
    u = User.find(1)
    u.comment_adds_to_tracker_enabled = false
    u.tracker_autodelete_old_contents = false
    u.save
    post :save_tracker_config, { :user => { :comment_adds_to_tracker_enabled => '1', :tracker_autodelete_old_contents => '1' } }
    assert_response :redirect
    assert_redirected_to '/cuenta/cuenta/tracker'
    u.reload
    assert_equal true, u.comment_adds_to_tracker_enabled
    assert_equal true, u.tracker_autodelete_old_contents
  end
  
  def test_should_save_notifications_options_without_newprofile_signatures
    sym_login 1
    u = User.find(1)
    u.notifications_global = false
    u.notifications_newmessages = false
    u.notifications_newregistrations = false
    u.notifications_trackerupdates = false
    u.save
    post :update_notifications, { :user => { :notifications_global => '1', :notifications_newmessages => '1', :notifications_newregistrations => 1, :notifications_trackerupdates => 1} }
    assert_response :redirect
    u.reload
    assert_equal true, u.notifications_global
    assert_equal true, u.notifications_newmessages
    assert_equal true, u.notifications_newregistrations
    assert_equal true, u.notifications_trackerupdates
  end
  
  def test_tracker_should_work
    sym_login 1
    get :tracker
    assert_response :success
  end
  
  def test_configuracion_should_work
    sym_login 1
    get :configuracion
    assert_response :success
  end
  
  def test_confirmar_should_work
    get :confirmar
    assert_response :success
  end
  
  def test_resendnewmail_should_work
    sym_login 1
    assert_count_increases(ActionMailer::Base.deliveries) do
      post :resendnewemail
      assert_redirected_to '/cuenta'
    end
  end
  
  def test_perfil_should_work
    sym_login 1
    get :perfil
    assert_response :success
  end
  
  def test_notificaciones_should_work
    sym_login 1
    get :notificaciones
    assert_response :success
  end
  
  def test_imagenes_should_work
    sym_login 1
    get :imagenes
    assert_response :success
  end
  
  def test_subir_imagen_should_work
    sym_login 1
    @u1 = User.find(1)
    f_count = @u1.get_my_files.size
    post :subir_imagen, { :file => fixture_file_upload('files/buddha.jpg', 'image/jpeg') }
    assert_equal f_count + 1, @u1.get_my_files.size  
    assert_response :redirect
  end
  
  def test_subir_imagen_shouldnt_throw_except_if_no_image
    sym_login 1
    @u1 = User.find(1)
    f_count = @u1.get_my_files.size
    [nil, ''].each do |t|
      post :subir_imagen, { :file =>  t}
      assert_equal f_count, @u1.get_my_files.size  
      assert_response :redirect
    end
  end
  
  def test_borrar_imagen_should_work
    test_subir_imagen_should_work
    f_count = @u1.get_my_files.size
    post :borrar_imagen, { :filename => 'buddha.jpg' }
    assert_response :success
    assert_equal f_count - 1, @u1.get_my_files.size
  end
  
  def test_save_avatar_should_work
    
    @u1 = User.find(1)
    @u1.change_avatar
    assert_nil @u1.avatar_id
    Factions.user_joins_faction(@u1, 1)
    sym_login 1
    post :save_avatar, { :new_avatar_id => 1 }
    assert_response :redirect
    @u1.reload
    assert_equal 1, @u1.avatar_id
    post :save_avatar, { :new_avatar_id => '' }
    assert_response :redirect
    assert_not_nil flash[:error]
    @u1.reload
    assert_equal 1, @u1.avatar_id
  end
  
  def test_should_update_custom_avatar
    sym_login 1
    u1 = User.find(1)
    av = u1.avatars.create({:name => 'fumancu', :submitter_user_id => 1})
    assert !av.new_record?
    post :custom_avatars_set, {:custom_avatars => { av.id.to_s => fixture_file_upload('files/buddha.jpg', 'file/jpeg') } }
    assert_redirected_to :action => 'avatar'
    av.reload
    assert av.path.include?('buddha.jpg')
  end
  
  def test_avatar_should_work
    sym_login 1
    get :avatar
    assert_response :success
  end
  
  def test_do_change_email_should_work
    @u1 = User.find(1)
    @u1.newemail = 'fulanoides@dadad.com'
    assert @u1.save
    post :do_change_email, { :k => @u1.validkey, :email => @u1.newemail}
    assert_redirected_to '/cuenta'
    @u1.reload
    assert_equal 'fulanoides@dadad.com', @u1.email
  end
  
  def test_resendsignup_should_work
    u = User.find_by_login('unconfirmed_user')
    assert_not_nil u
    assert_count_increases(ActionMailer::Base.deliveries) do
      post :resendsignup, {:post => { :email => u.email }}
    end
  end
  
  def test_set_default_portal
    assert_raises(AccessDenied) { get :set_default_portal }
    sym_login 1
    post :set_default_portal, :new_portal => 'arena'
    assert_response :success
    u1 = User.find(1)
    assert_equal 'arena', u1.default_portal
  end
end