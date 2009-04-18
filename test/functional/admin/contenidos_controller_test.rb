require 'test_helper'

class Admin::ContenidosControllerTest < ActionController::TestCase
  
  test "should_allow_to_publish_content_if_user_is_not_the_author" do
    n = News.create({ :title => 'mi noticiaaaa', :description => 'mi summaryyyy', :terms => 1, :user_id => User.find_by_login('panzer') })
    assert_not_nil n
    assert_equal 'mi noticiaaaa', n.title
    sym_login :mralariko
    publishing_decisions_count = PublishingDecision.count
    post :publish_content, { :id => n.unique_content.id }
    assert_response :redirect
    assert_equal publishing_decisions_count + 1, PublishingDecision.count
  end
  
  test "mass_moderate_should_work_if_mass_approve" do
    n = News.create({ :title => 'mi noticiaaaa', :description => 'mi summaryyyy', :terms => 1, :user_id => User.find_by_login('panzer') })
    assert_not_nil n
    Cms.modify_content_state(n, User.find(1), Cms::PENDING)
    n.reload
    assert_equal Cms::PENDING, n.state
    sym_login 1
    post :mass_moderate, { :mass_action => 'publish', :items => [n.unique_content.id]}
    n.reload
    assert_equal Cms::PUBLISHED, n.state
  end
  
  test "mass_moderate_should_work_if_mass_deny" do
    n = News.create({ :title => 'mi noticiaaaa', :description => 'mi summaryyyy', :terms => 1, :user_id => User.find_by_login('panzer') })
    assert_not_nil n
    Cms.modify_content_state(n, User.find(1), Cms::PENDING)
    n.reload
    assert_equal Cms::PENDING, n.state
    sym_login 1
    post :mass_moderate, { :mass_action => 'deny', :items => [n.unique_content.id]}
    n.reload
    assert_equal Cms::DELETED, n.state
  end
  
  test "switch_decision_should_work" do
    test_should_allow_to_deny_content_if_user_is_not_the_author_and_deny_reason
    sym_login 1
    pd = PublishingDecision.find(:first, :order => 'id desc')
    assert !pd.publish
    post :switch_decision, { :id => pd.id}
    assert_response :redirect
    pd.reload
    assert pd.publish
  end
  
  test "recover_should_work" do
    sym_login 1
    n = News.find(1)
    Cms.modify_content_state(n, User.find(1), Cms::DELETED, "feooote")
    n.reload
    assert_equal Cms::DELETED, n.state
    post :recover, :id => n.unique_content.id
    assert_response :success
    n.reload
    assert_equal Cms::PUBLISHED, n.state
  end
  
  test "should_not_allow_to_deny_content_if_user_is_not_the_author_but_no_deny_reason" do
    n = News.create({ :title => 'mi noticiaaaa', :description => 'mi summaryyyy', :terms => 1, :user_id => User.find_by_login('panzer') })
    assert_not_nil n
    assert_equal 'mi noticiaaaa', n.title
    sym_login :mralariko
    publishing_decisions_count = PublishingDecision.count
    post :deny_content, { :id => n.unique_content.id }
    assert_response :redirect
    assert_equal publishing_decisions_count, PublishingDecision.count
  end
  
  test "should_allow_to_deny_content_if_user_is_not_the_author_and_deny_reason" do
    @n = News.create({ :title => 'mi noticiaaaa', :description => 'mi summaryyyy', :terms => 1, :user_id => User.find_by_login('panzer') })
    assert_not_nil @n
    assert_equal 'mi noticiaaaa', @n.title
    sym_login :mralariko
    publishing_decisions_count = PublishingDecision.count
    post :deny_content, { :id => @n.unique_content.id, :deny_reason => 'me molo a mi mismo' }
    assert_response :redirect
    assert_equal publishing_decisions_count + 1, PublishingDecision.count
  end
  
  test "change_authorship_should_work" do
    n = News.find(1)
    assert_equal 1, n.user_id
    sym_login 1
    u2 = User.find(2)
    post :change_authorship, { :content_id => n.unique_content.id, :login => u2.login}
    assert_response :redirect
    n.reload
    assert_equal 2, n.user_id
  end
  
  test "content_must_be_at_0_00_when_sent_to_state1" do
  end
  
  #  test "content_must_be_published_if_editor_votes_that" do
  #  end
  
  #  test "content_must_be_denied_if_editor_votes_that" do
  #  end
  
  #  test "content_must_increment" do
  
  test "should_see_index_if_admin" do
    sym_login 1
    get :index
    assert_response :success
  end
  
  test "should_see_papelera_if_admin" do
    sym_login 1
    get :papelera
    assert_response :success
  end
  
  test "should_see_hotmap_if_admin" do
    sym_login 1
    get :hotmap
    assert_response :success
  end
  
  test "should_see_ultimas_decisiones_if_admin_and_gm" do
    sym_login 1
    get :ultimas_decisiones
    assert_response :success
  end
  
  test "should_see_ultimas_decisiones_if_admin_and_factions_portal" do
    @request.host = 'ut.gamersmafia.com'
    sym_login 1
    get :ultimas_decisiones
    assert_response :success
  end
  
  test "should_see_ultimas_decisiones_if_admin_and_gm_and_platforms_portal" do
    @request.host = 'wii.gamersmafia.com'
    sym_login 1
    get :ultimas_decisiones
    assert_response :success
  end
  
  test "report" do
    sym_login 1
    assert_count_increases(SlogEntry) do
      post :report, :id => Content.find(:first).id
    end
    assert_response :success
  end
  
  test "report_with_bazar_district_content" do
    sym_login 1
    assert_count_increases(SlogEntry) do
      post :report, :id => 1113
    end
    assert_response :success
  end
  
  test "orphaned" do
    sym_login 1
    get :huerfanos
    assert_response :success
  end
end
