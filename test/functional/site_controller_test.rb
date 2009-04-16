require 'test_helper'
require 'site_controller'

# Re-raise errors caught by the controller.
class SiteController; def rescue_action(e) raise e end; end

class SiteControllerTest < ActionController::TestCase
  def setup
    @controller = SiteController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end
  
  basic_test :carcel, :smileys, :tu_web_de_clan_gratis, :rss, :contactar, :privacidad, :album, :fusiones, :webs_de_clanes, :logo
  
  def test_maintain_lock
    l = ContentsLock.create({:content_id => 1, :user_id => 1})
    ContentsLock.db_query("UPDATE contents_locks set updated_on = now() - '30 seconds'::interval WHERE id = #{l.id}")
    sym_login(1)
    get :maintain_lock, {:id => l.id}
    assert_response :success
    l.reload
    assert l.updated_on > 10.seconds.ago, l.updated_on
  end
  
  def test_get_banners_of_gallery
    assert_raises(ActiveRecord::RecordNotFound) { get :get_banners_of_gallery }
    
    get :get_banners_of_gallery, :gallery => 'simples'
    assert_response :success
  end
  
  def test_new_chatline_should_require_user
    assert_raises(AccessDenied) { post :new_chatline, {:line => 'foo'} }
  end
  
  def test_new_chatline_should_work
    sym_login 1
    assert_count_increases(Chatline) do
      post :new_chatline, {:line => 'foo'}
    end
  end
  
  def test_rate_content_should_work_if_not_authed
    #User.connection.query_cache_enabled = false
    assert_count_increases(ContentRating) do
      post :rate_content, { :content_rating => { :rating => '1', :content_id => 1}}
    end
    assert_response :success
  end
  
  def test_unserviceable_domain
    get :unserviceable_domain
    assert_response :success
  end
  
  def test_te_buscamos
    get :te_buscamos
    assert_response :success
  end
  
  def test_rate_content_should_work_if_authed
    sym_login 2
    assert_count_increases(ContentRating) do
      post :rate_content, { :content_rating => { :rating => '1', :content_id => 1}}
    end
    assert_response :success
  end
  
  def test_acercade
    get :index
    assert_response :success
    assert_template 'site/index'
    # assert_valid_markup
  end
  
  def test_add_to_tracker_should_work
    sym_login 1
    assert_count_increases(TrackerItem) do
      post :add_to_tracker, {:id => 2, :redirto => '/'}
      assert_response :redirect
    end
  end
  
  def test_get_non_updated_tracker_items
    sym_login 1
    get :x, {:ids => '1,2,3'}
    assert_response :success
  end
  
  def test_x_with_another_visitor_id_should_update_cookie_visitor_id_when_login_in
    sym_login 1
    @request.cookies['__stma'] = CGI::Cookie.new('__stma', '77524682.953150376.1212331927.1212773764.1212777897.14')
    treated_visitors = User.db_query("SELECT COUNT(*) FROM treated_visitors")[0]['count'].to_i
    get :x, '_xab' => {1 => 2}, '_xvi' => '77524682'
    assert_response :success
    assert_equal treated_visitors + 1, User.db_query("SELECT COUNT(*) FROM treated_visitors")[0]['count'].to_i
    
    dbinfo = User.db_query("SELECT * FROM treated_visitors ORDER BY id desc LIMIT 1")[0]
    assert_equal 2, dbinfo['treatment'].to_i
    
    @controller = SiteController.new # to reset
    # Simulamos que conecta desde otro pc
    @request.cookies['__stma'] = CGI::Cookie.new('__stma', '23131.953150376.1212331927.1212773764.1212777897.14')
    sym_login 1
    get :x, '_xab' => {1 => 1}, '_xvi' => '23131'
    assert_response :success
    assert @response.cookies['__stma'].to_s.include?('77524682')
  end
  
  def test_x_with_changed_treatment
    @request.cookies['__stma'] = CGI::Cookie.new('__stma', '77524682.953150376.1212331927.1212773764.1212777897.14')
    treated_visitors = User.db_query("SELECT COUNT(*) FROM treated_visitors")[0]['count'].to_i
    get :x, '_xab' => {1 => 2}, '_xvi' => '77524682'
    assert_response :success
    assert_equal treated_visitors + 1, User.db_query("SELECT COUNT(*) FROM treated_visitors")[0]['count'].to_i
    
    dbinfo = User.db_query("SELECT * FROM treated_visitors ORDER BY id desc LIMIT 1")[0]
    assert_equal 2, dbinfo['treatment'].to_i
    
    @controller = SiteController.new # to reset
    
    sym_login 1
    get :x, '_xab' => {1 => 1}, '_xvi' => '77524682'
    assert_response :success
    
    dbinfo = User.db_query("SELECT * FROM treated_visitors ORDER BY id desc LIMIT 1")[0]
    
    assert_equal 1, dbinfo['user_id'].to_i
    assert_equal 1, dbinfo['treatment'].to_i
    assert_equal treated_visitors + 2, User.db_query("SELECT COUNT(*) FROM treated_visitors")[0]['count'].to_i
  end
  
  def test_trastornos
    get :trastornos
    assert_response :success
  end
  
  
  def test_del_from_tracker_should_work
    test_add_to_tracker_should_work
    ti = TrackerItem.find(:first, :order => 'id desc')
    assert ti.is_tracked?
    post :del_from_tracker, {:id => 2, :redirto => '/'}
    assert_response :redirect
    ti.reload
    assert !ti.is_tracked?
  end
  
  def test_should_redir_old_acercade_url
    get :acercade
    assert_redirected_to '/site'
  end
  
  def test_banners
    get :banners
    assert_response :success
  end
  
  def test_netiquette
    get :netiquette
    assert_response :success
  end
  
  def test_online_should_work_with_mini
    User.db_query("UPDATE users set lastseen_on = now()")
    get :online
    assert_response :success
  end
  
  def test_online_should_work_with_big
    User.db_query("UPDATE users set lastseen_on = now()")
    @request.cookies['chatpref'] = CGI::Cookie.new('chatpref', 'big')
    get :online
    assert_response :success
  end
  
  def test_update_chatlines_should_work_with_mini
    User.db_query("UPDATE chatlines set created_on = now()")
    get :update_chatlines
    assert_response :success
  end
  
  def test_update_chatlines_should_work_with_big
    User.db_query("UPDATE chatlines set created_on = now()")
    @request.cookies['chatpref'] = CGI::Cookie.new('chatpref', 'big')
    get :update_chatlines
    assert_response :success
  end
  
  def test_faq
    get :faq
    assert_response :success
  end
  
  def test_banners_bottom
    get :banners_bottom
    assert_response :success
  end
  
  def test_banners_duke
    get :banners_duke
    assert_response :success
  end
  
  def test_banners_misc
    get :banners_misc
    assert_response :success
  end  
  
  def test_staff
    get :staff
    assert_response :success
  end  
  
  def test_ejemplos_guids
    get :ejemplos_guids
    assert_response :success
  end
  
  def test_colabora
    get :colabora
    assert_response :success
  end
  
  def test_transfer_should_redirect_if_all_missing
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {}
    assert_redirected_to '/'
  end
  
  def test_transfer_should_redirect_if_recipient_class_empty
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {:recipient_class => ''}
    assert_redirected_to '/'
  end
  
  def test_transfer_should_redirect_if_not_found_recipient
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {:sender_class => 'User', :sender_id => 1, :recipient_class => 'User', :recipient_user_login => 'bananito', :description => 'foo', :ammount => '500'}
    assert_redirected_to '/'
  end
  
  def test_transfer_should_redirect_if_no_description
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {:sender_class => 'User', :sender_id => 1, :recipient_class => 'User', :recipient_user_login => 'panzer', :description => '', :ammount => '500'}
    assert_redirected_to '/'
  end
  
  def test_transfer_should_redirect_if_no_ammount
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {:sender_class => 'User', :sender_id => 1, :recipient_class => 'User', :recipient_user_login => 'panzer', :description => 'foobar', :ammount => ''}
    assert_redirected_to '/'
  end
  
  def test_transfer_should_redirect_if_same_sender_and_recipient
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {:sender_class => 'User', :sender_id => 1, :recipient_class => 'User', :recipient_user_login => 'superadmin', :description => 'foobar', :ammount => '500'}
    assert_redirected_to '/'
  end
  
  def test_transfer_should_show_confirm_dialog_if_all_existing
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {:sender_class => 'User', :sender_id => 1, :recipient_class => 'User', :recipient_user_login => 'panzer', :description => 'foobar', :ammount => '1'}
    assert_response :success
    assert_template 'site/confirmar_transferencia'
  end
  
  
  def test_transferencia_confirmada
    test_transfer_should_show_confirm_dialog_if_all_existing
    assert_count_increases(CashMovement) do
      post :transferencia_confirmada, {:redirto => '/', :sender_class => 'User', :sender_id => 1, :recipient_class => 'User', :recipient_id => User.find_by_login('panzer').id, :description => 'foobar', :ammount => '1'}
    end
    assert_response :redirect
  end
  
  
  def test_should_update_online_state_if_x
    sym_login(1)
    u = User.find(1)
    u.lastseen_on = 1.day.ago
    u.save
    get :x
    assert_response :success
    u.reload
    assert u.lastseen_on.to_i > 1.day.ago.to_i
    assert u.lastseen_on.to_i > Time.now.to_i - 2
  end
  
  def test_del_chatline_should_work
    test_new_chatline_should_work
    assert_count_decreases(Chatline) do
      post :del_chatline, {:id => Chatline.find(:first).id}
    end
    assert_response :success
  end
  
  
  def test_should_do_nothing_if_x_with_anonymous
    get :x
    assert_response :success
  end
  
  def test_should_properly_acknowledge_resurrection
    u1 = User.find(1)
    fp = u1.faith_points
    u2 = User.find(2)
    u2.lastseen_on = 4.months.ago
    u2.resurrected_by_user_id = 1
    u2.resurrection_started_on = 1.minute.ago
    u2.save
    mails_sent = ActionMailer::Base.deliveries.size
    
    sym_login(2)
    get :x
    assert_response :success
    
    u1.reload
    assert_equal Faith::FPS_ACTIONS['resurrection'] + fp, u1.faith_points
    assert_equal mails_sent + 1, ActionMailer::Base.deliveries.size # el email de aviso  referer
    assert_equal u1.email, ActionMailer::Base.deliveries.at(-1).to[0]
  end
  
  def test_should_clean_html
    content = URI::escape('hello world') # usamos URI::escape en lugar de CGI::escape porque CGI::escape es incompatible con unescape de javascript
    sym_login 1
    post :clean_html, { :editorId => 'fuubar', :content => content }
    assert_response :success
    expected_response = <<-END
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<response>
  <method>wsEditorUpdateContentRemote</method>
  <result><![CDATA[var res = new Object;
  res.editorId = 'fuubar';
res.content = unescape('#{content}');]]></result>
</response>
    END
    assert_equal expected_response, @response.body
  end
  
  #  def test_should_count_hits_for_ads
  #    initial = User.db_query("SELECT count(*) from stats.ads_shown")[0]['count'].to_i
  #    get :colabora
  #    assert_response :success
  #    assert_equal initial + 1, User.db_query("SELECT count(*) from stats.ads_shown")[0]['count'].to_i
  #  end
  
  def test_cnta_should_properly_account_for_hits
    initial_count = User.db_query("SELECT count(*) FROM stats.ads")[0]['count'].to_i
    get :cnta, :url => 'http://google.com/\'' # para testear tb q  no se produzca sql injection
    assert_response :created
    assert_equal initial_count + 1, User.db_query("SELECT count(*) FROM stats.ads")[0]['count'].to_i
  end 
  
  def test_cnta_should_properly_account_for_hits_with_user_id
    sym_login 1
    initial_count = User.db_query("SELECT count(*) FROM stats.ads")[0]['count'].to_i
    get :cnta, :url => 'http://google.com/', :element_id => 'wiii'
    assert_response :created
    assert_equal initial_count + 1, User.db_query("SELECT count(*) FROM stats.ads")[0]['count'].to_i
    assert_equal 1, User.db_query("SELECT user_id FROM stats.ads ORDER BY id desc limit 1")[0]['user_id'].to_i
    assert_equal 'wiii', User.db_query("SELECT element_id FROM stats.ads ORDER BY id desc limit 1")[0]['element_id']
  end
  
  def test_slog_should_work_if_hq
    u2 = User.find(2)
    u2.is_hq = true
    u2.save
    sym_login 2
    get :slog
    assert_response :success
    assert_template 'slog_html'
  end
  
  def test_should_track_email_read_on
    message_key = Kernel.rand.to_s
    se = SentEmail.new(:title => 'foo', :sender => 'fulanito', :recipient => 'menganito', :message_key => message_key)
    start = Time.now
    assert se.save 
    get :logoe, :mid => message_key
    assert_response :success
    se.reload
    assert se.first_read_on.to_i >= start.to_i 
  end
  
  def test_do_contactar_should_send_email
    m_count = Message.count
    post :do_contactar, :subject => 'Otros', :message => 'hola tio', :email => 'fulanito de tal'
    assert_response :redirect
    assert_equal m_count, Message.count
    
    # anon
    assert_count_increases(ActionMailer::Base.deliveries) do
      post :do_contactar, :subject => 'Otros', :message => 'hola tio', :email => 'fulanito de tal', :fsckspmr => SiteController.do_contactar_key
      assert_response :redirect
    end
    
    # reg
    assert_count_increases(Message) do
      sym_login 2
      post :do_contactar, :subject => 'Otros', :message => 'hola tio', :email => 'fulanito de tal', :fsckspmr => SiteController.do_contactar_key
      assert_response :redirect
    end    
  end
  
  def test_stats_hipotesis
    #abn = AbTest.new(:name => 'foo', :active => true, :metrics => ['comments'], :treatments => 2)
    #assert abn.save
    assert_raises(AccessDenied) { get :stats_hipotesis }
    sym_login 1
    get :stats_hipotesis
    assert_response :success
  end
  
  def test_stats_hipotesis_archivo
    assert_raises(AccessDenied) { get :stats_hipotesis_archivo }
    sym_login 1
    get :stats_hipotesis_archivo
    assert_response :success
  end
  
  def test_x_should_work_with_funky_params
    # @eng['USER_AGENT'] = ''
  end
  
  def test_slog_options_switch
    
  end
  
  def test_report_content_form
    assert_raises(AccessDenied) { get :report_content_form }
    sym_login 1
    get :report_content_form
    assert_response :success
  end
  
  def test_recommend_to_friend
    assert_raises(AccessDenied) { get :recommend_to_friend, :content_id => Content.find(:first).id }
    sym_login 1
    get :report_content_form, :content_id => Content.find(:first).id
    assert_response :success
  end
  
  def test_do_recommend_to_friend_not_friend
    sym_login 1
    rcount = ContentsRecommendation.count
    raulinho = User.find_by_login('raulinho')
    post :do_recommend_to_friend, :content_id => 1, :friends => [raulinho.id.to_s]
    assert_equal rcount, ContentsRecommendation.count
  end
  
  def test_do_recommend_to_friend_ok
    sym_login 1
    panzer = User.find_by_login('panzer')
    
    assert_count_increases(ContentsRecommendation) do
      post :do_recommend_to_friend, :content_id => 1, :friends => [panzer.id.to_s], :comment => 'feoo'
    end
  end
  
  def test_do_recommend_to_friend_but_friend_already_visited
    sym_login 1
    panzer = User.find_by_login('panzer')
    assert_count_increases(TrackerItem) do
      TrackerItem.create(:content_id => 1, :user_id => User.find_by_login('panzer').id, :lastseen_on => Time.now)
    end
    
    assert_count_increases(ContentsRecommendation) do
      post :do_recommend_to_friend, :content_id => 1, :friends => [panzer.id.to_s]
    end    
  end
  
  def test_root_term_children_if_not_authed
    assert_raises(AccessDenied) { get :root_term_children, :id => 1, :content_type => 'Tutorial' }
  end
  
  def test_root_term_children_if_not_authed
    sym_login 1
    
    get :root_term_children, :id => 1, :content_type => 'Tutorial'
    assert_response :success
  end
end