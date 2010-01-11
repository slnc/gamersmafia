require 'test_helper'

class SiteControllerTest < ActionController::TestCase  
  basic_test :carcel, :smileys, :rss, :contactar, :privacidad, :album, :fusiones, :webs_de_clanes, :logo, :responsabilidades, :portales, :novedades

  test "should_create_pageview" do
    dbr = User.db_query("SELECT count(*) FROM stats.pageviews")
    @request.cookies['__stma'] = 'aas'
    get :x
    assert_response :success
    dbr1 = User.db_query("SELECT count(*) FROM stats.pageviews")
    assert_equal dbr[0]['count'].to_i + 1, dbr1[0]['count'].to_i 
  end
  
  test "maintain_lock" do
    l = ContentsLock.create({:content_id => 1, :user_id => 1})
    ContentsLock.db_query("UPDATE contents_locks set updated_on = now() - '30 seconds'::interval WHERE id = #{l.id}")
    sym_login(1)
    get :maintain_lock, {:id => l.id}
    assert_response :success
    l.reload
    assert l.updated_on > 10.seconds.ago, l.updated_on
  end
  
#  test "mrachmed clasifica comentarios" do
#    [:mrachmed_clasifica_comentarios_good, :mrachmed_clasifica_comentarios_bad].each do |act|
#      assert_raises(AccessDenied) { get act }
#    end
#    
#    sym_login 1
#    
#    assert_count_increases(CommentViolationOpinion) do
#      c_id = Comment.first.id
#      post :mrachmed_clasifica_comentarios_good, :comment_id => c_id
#      assert_redirected_to "/site/mrachmed_clasifica_comentarios?prev_comment_id=#{c_id}"
#      assert flash[:error].nil?
#    end
#    CommentViolationOpinion.last.destroy
#    
#    assert_count_increases(CommentViolationOpinion) do
#      c_id = Comment.first.id
#      post :mrachmed_clasifica_comentarios_bad, :comment_id => c_id
#      assert_redirected_to "/site/mrachmed_clasifica_comentarios?prev_comment_id=#{c_id}"
#      assert flash[:error].nil?
#    end
#    
#    [:mrachmed_clasifica_comentarios_good, :mrachmed_clasifica_comentarios_bad].each do |act|
#      get act
#      assert_response :success
#      assert flash[:error]
#    end
#  end
  
  test "get_banners_of_gallery" do
    assert_raises(ActiveRecord::RecordNotFound) { get :get_banners_of_gallery }
    
    get :get_banners_of_gallery, :gallery => 'simples'
    assert_response :success
  end
  
  test "new_chatline_should_require_user" do
    assert_raises(AccessDenied) { post :new_chatline, {:line => 'foo'} }
  end
  
  test "mobjobs only registered" do
    assert_raises(AccessDenied) { get :el_callejon }
    sym_login 1
    get :el_callejon
    assert_response :success
  end
  
  test "new_chatline_should_work" do
    sym_login 1
    assert_count_increases(Chatline) do
      post :new_chatline, {:line => 'foo'}
    end
  end
  
  test "rate_content_should_work_if_not_authed" do
    #User.connection.query_cache_enabled = false
    assert_count_increases(ContentRating) do
      post :rate_content, { :content_rating => { :rating => '1', :content_id => 1}}
    end
    assert_response :success
  end
  
  test "unserviceable_domain" do
    get :unserviceable_domain
    assert_response :success
  end
  
  test "te_buscamos" do
    get :te_buscamos
    assert_response :success
  end
  
  test "rate_content_should_work_if_authed" do
    sym_login 2
    assert_count_increases(ContentRating) do
      post :rate_content, { :content_rating => { :rating => '1', :content_id => 1}}
    end
    assert_response :success
  end
  
  test "acercade" do
    get :index
    assert_response :success
    assert_template 'site/index'
    # assert_valid_markup
  end
  
  test "add_to_tracker_should_work" do
    sym_login 1
    assert_count_increases(TrackerItem) do
      post :add_to_tracker, {:id => 2, :redirto => '/'}
      assert_response :redirect
    end
  end
  
  test "get_non_updated_tracker_items" do
    sym_login 1
    get :x, {:ids => '1,2,3'}
    assert_response :success
  end
  
  test "x_with_another_visitor_id_should_update_cookie_visitor_id_when_login_in" do
    sym_login 1
    @request.cookies['__stma'] = '77524682.953150376.1212331927.1212773764.1212777897.14'
    treated_visitors = User.db_query("SELECT COUNT(*) FROM treated_visitors")[0]['count'].to_i
    get :x, '_xab' => {1 => 2}, '_xvi' => '77524682'
    assert_response :success
    assert_equal treated_visitors + 1, User.db_query("SELECT COUNT(*) FROM treated_visitors")[0]['count'].to_i
    
    dbinfo = User.db_query("SELECT * FROM treated_visitors ORDER BY id desc LIMIT 1")[0]
    assert_equal 2, dbinfo['treatment'].to_i
    
    @controller = SiteController.new # to reset
    # Simulamos que conecta desde otro pc
    @request.cookies['__stma'] = '23131.953150376.1212331927.1212773764.1212777897.14'
    sym_login 1
    get :x, '_xab' => {1 => 1}, '_xvi' => '23131'
    assert_response :success
    assert @response.cookies['__stma'].to_s.include?('77524682')
  end
  
  test "x_with_changed_treatment" do
    @request.cookies['__stma'] = '77524682.953150376.1212331927.1212773764.1212777897.14'
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
  
  test "trastornos" do
    get :trastornos
    assert_response :success
  end
  
  
  test "del_from_tracker_should_work" do
    test_add_to_tracker_should_work
    ti = TrackerItem.find(:first, :order => 'id desc')
    assert ti.is_tracked?
    post :del_from_tracker, {:id => 2, :redirto => '/'}
    assert_response :redirect
    ti.reload
    assert !ti.is_tracked?
  end
  
  test "should_redir_old_acercade_url" do
    get :acercade
    assert_redirected_to '/site'
  end
  
  test "banners" do
    get :banners
    assert_response :success
  end
  
  test "netiquette" do
    get :netiquette
    assert_response :success
  end
  
  test "online_should_work_with_mini" do
    User.db_query("UPDATE users set lastseen_on = now()")
    get :online
    assert_response :success
  end
  
  test "online_should_work_with_big" do
    User.db_query("UPDATE users set lastseen_on = now()")
    @request.cookies['chatpref'] = 'big'
    get :online
    assert_response :success
  end
  
  test "update_chatlines_should_work_with_mini" do
    User.db_query("UPDATE chatlines set created_on = now()")
    get :update_chatlines
    assert_response :success
  end
  
  test "update_chatlines_should_work_with_big" do
    User.db_query("UPDATE chatlines set created_on = now()")
    @request.cookies['chatpref'] = 'big'
    get :update_chatlines
    assert_response :success
  end
  
  test "faq" do
    get :faq
    assert_response :success
  end
  
  test "banners_duke" do
    get :banners_duke
    assert_response :success
  end
  
  test "banners_misc" do
    get :banners_misc
    assert_response :success
  end  
  
  test "staff" do
    get :staff
    assert_response :success
  end  
  
  test "ejemplos_guids" do
    get :ejemplos_guids
    assert_response :success
  end
  
  test "transfer_should_redirect_if_all_missing" do
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {}
    assert_redirected_to '/'
  end
  
  test "transfer_should_redirect_if_recipient_class_empty" do
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {:recipient_class => ''}
    assert_redirected_to '/'
  end
  
  test "transfer_should_redirect_if_not_found_recipient" do
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {:sender_class => 'User', :sender_id => 1, :recipient_class => 'User', :recipient_user_login => 'bananito', :description => 'foo', :ammount => '500'}
    assert_redirected_to '/'
  end
  
  test "transfer_should_redirect_if_no_description" do
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {:sender_class => 'User', :sender_id => 1, :recipient_class => 'User', :recipient_user_login => 'panzer', :description => '', :ammount => '500'}
    assert_redirected_to '/'
  end
  
  test "transfer_should_redirect_if_no_ammount" do
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {:sender_class => 'User', :sender_id => 1, :recipient_class => 'User', :recipient_user_login => 'panzer', :description => 'foobar', :ammount => ''}
    assert_redirected_to '/'
  end
  
  test "transfer_should_redirect_if_same_sender_and_recipient" do
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {:sender_class => 'User', :sender_id => 1, :recipient_class => 'User', :recipient_user_login => 'superadmin', :description => 'foobar', :ammount => '500'}
    assert_redirected_to '/'
  end
  
  test "transfer_should_show_confirm_dialog_if_all_existing" do
    Bank.transfer(:bank, User.find(1), 10, 'f')
    sym_login(1)
    post :confirmar_transferencia, {:sender_class => 'User', :sender_id => 1, :recipient_class => 'User', :recipient_user_login => 'panzer', :description => 'foobar', :ammount => '1'}
    assert_response :success
    assert_template 'site/confirmar_transferencia'
  end
  
  
  test "transferencia_confirmada" do
    test_transfer_should_show_confirm_dialog_if_all_existing
    assert_count_increases(CashMovement) do
      post :transferencia_confirmada, {:redirto => '/', :sender_class => 'User', :sender_id => 1, :recipient_class => 'User', :recipient_id => User.find_by_login('panzer').id, :description => 'foobar', :ammount => '1'}
    end
    assert_response :redirect
  end
  
  
  test "should_update_online_state_if_x" do
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
  
  test "del_chatline_should_work" do
    test_new_chatline_should_work
    assert_count_decreases(Chatline) do
      post :del_chatline, {:id => Chatline.find(:first).id}
    end
    assert_response :success
  end
  
  
  test "should_do_nothing_if_x_with_anonymous" do
    get :x
    assert_response :success
  end
  
  test "should_properly_acknowledge_resurrection" do
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
  
  test "should_clean_html" do
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
  
  #  test "should_count_hits_for_ads" do
  #    initial = User.db_query("SELECT count(*) from stats.ads_shown")[0]['count'].to_i
  #    get :colabora
  #    assert_response :success
  #    assert_equal initial + 1, User.db_query("SELECT count(*) from stats.ads_shown")[0]['count'].to_i
  #  end
  
  test "cnta_should_properly_account_for_hits" do
    initial_count = User.db_query("SELECT count(*) FROM stats.ads")[0]['count'].to_i
    get :cnta, :url => 'http://google.com/\'' # para testear tb q  no se produzca sql injection
    assert_response :created
    assert_equal initial_count + 1, User.db_query("SELECT count(*) FROM stats.ads")[0]['count'].to_i
  end 
  
  test "cnta_should_properly_account_for_hits_with_user_id" do
    sym_login 1
    initial_count = User.db_query("SELECT count(*) FROM stats.ads")[0]['count'].to_i
    get :cnta, :url => 'http://google.com/', :element_id => 'wiii'
    assert_response :created
    assert_equal initial_count + 1, User.db_query("SELECT count(*) FROM stats.ads")[0]['count'].to_i
    assert_equal 1, User.db_query("SELECT user_id FROM stats.ads ORDER BY id desc limit 1")[0]['user_id'].to_i
    assert_equal 'wiii', User.db_query("SELECT element_id FROM stats.ads ORDER BY id desc limit 1")[0]['element_id']
  end
  
  test "should_track_email_read_on" do
    message_key = Kernel.rand.to_s
    se = SentEmail.new(:title => 'foo', :sender => 'fulanito', :recipient => 'menganito', :message_key => message_key)
    start = Time.now
    assert se.save 
    get :logoe, :mid => message_key
    assert_response :success
    se.reload
    assert se.first_read_on.to_i >= start.to_i 
  end
  
  test "do_contactar_should_send_email" do
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
  
  test "stats_hipotesis" do
    #abn = AbTest.new(:name => 'foo', :active => true, :metrics => ['comments'], :treatments => 2)
    #assert abn.save
    assert_raises(AccessDenied) { get :stats_hipotesis }
    sym_login 1
    get :stats_hipotesis
    assert_response :success
  end
  
  test "stats_hipotesis_archivo" do
    assert_raises(AccessDenied) { get :stats_hipotesis_archivo }
    sym_login 1
    get :stats_hipotesis_archivo
    assert_response :success
  end
  
  test "x_should_work_with_funky_params" do
    # @eng['USER_AGENT'] = ''
  end
  
  test "slog_options_switch" do
    
  end
  
  test "report_content_form" do
    assert_raises(AccessDenied) { get :report_content_form }
    sym_login 1
    get :report_content_form
    assert_response :success
  end
  
  test "recommend_to_friend" do
    assert_raises(AccessDenied) { get :recommend_to_friend, :content_id => Content.find(:first).id }
    sym_login 1
    get :report_content_form, :content_id => Content.find(:first).id
    assert_response :success
  end
  
  test "do_recommend_to_friend_not_friend" do
    sym_login 1
    rcount = ContentsRecommendation.count
    raulinho = User.find_by_login('raulinho')
    post :do_recommend_to_friend, :content_id => 1, :friends => [raulinho.id.to_s]
    assert_equal rcount, ContentsRecommendation.count
  end
  
  test "do_recommend_to_friend_ok" do
    sym_login 1
    panzer = User.find_by_login('panzer')
    
    assert_count_increases(ContentsRecommendation) do
      post :do_recommend_to_friend, :content_id => 1, :friends => [panzer.id.to_s], :comment => 'feoo'
    end
    assert_equal 'feoo', ContentsRecommendation.last.comment
  end
  
  test "do_recommend_to_friend_but_friend_already_visited" do
    sym_login 1
    panzer = User.find_by_login('panzer')
    assert_count_increases(TrackerItem) do
      TrackerItem.create(:content_id => 1, :user_id => User.find_by_login('panzer').id, :lastseen_on => Time.now)
    end
    
    assert_count_increases(ContentsRecommendation) do
      post :do_recommend_to_friend, :content_id => 1, :friends => [panzer.id.to_s]
    end    
  end
  
  test "root_term_children_if_not_authed" do
    assert_raises(AccessDenied) { get :root_term_children, :id => 1, :content_type => 'Tutorial' }
  end
  
  test "root_term_children_if_authed" do
    sym_login 1
    
    get :root_term_children, :id => 1, :content_type => 'Tutorial'
    assert_response :success
  end
end
