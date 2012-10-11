# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::ContenidosControllerTest < ActionController::TestCase

  def create_some_news
    News.create({
        :title => 'mi noticiaaaa',
        :description => 'mi summaryyyy',
        :terms => 1,
        :user_id => User.find_by_login('panzer'),
    })
  end

  test "should_not_allow_to_publish_content_if_user_no skill" do
    n = self.create_some_news
    assert_not_nil n
    sym_login :mralariko
    assert_raises(AccessDenied) do
      post :publish_content, { :id => n.unique_content.id }
    end
  end

  test "should_allow_to_publish_content_if_user_is_not_the_author" do
    give_skill("mralariko", "ContentModerationQueue")
    sym_login :mralariko
    n = self.create_some_news
    assert_equal 'mi noticiaaaa', n.title
    publishing_decisions_count = PublishingDecision.count
    post :publish_content, { :id => n.unique_content.id }
    assert_response :redirect
    assert_equal publishing_decisions_count + 1, PublishingDecision.count
  end

  test "mass_moderate_should_work_if_mass_approve" do
    n = self.create_some_news
    Content.send_draft_to_moderation_queue(n)
    n.reload
    assert_equal Cms::PENDING, n.state
    sym_login 1
    post :mass_moderate, {
        :mass_action => 'publish',
        :items => [n.unique_content.id],
    }
    n.reload
    assert_equal Cms::PUBLISHED, n.state
  end

  test "mass_moderate_should_work_if_mass_deny" do
    n = self.create_some_news
    Content.send_draft_to_moderation_queue(n)
    n.reload
    assert_equal Cms::PENDING, n.state
    sym_login 1
    post :mass_moderate, {
        :mass_action => 'deny',
        :items => [n.unique_content.id],
    }
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
    Content.delete_content(n, User.find(1), "feooote")
    n.reload
    assert_equal Cms::DELETED, n.state
    post :recover, :id => n.unique_content.id
    assert_response :success
    n.reload
    assert_equal Cms::PUBLISHED, n.state
  end

  test "should_not_allow_to_deny_content_if_user_is_not_the_author_but_no_deny_reason" do
    n = self.create_some_news
    give_skill("mralariko", "ContentModerationQueue")
    sym_login :mralariko
    publishing_decisions_count = PublishingDecision.count
    post :deny_content, { :id => n.unique_content.id }
    assert_response :redirect
    assert_equal publishing_decisions_count, PublishingDecision.count
  end

  test "should_allow_to_deny_content_if_user_is_not_the_author_and_deny_reason" do
    User.find_by_login("mralariko").users_skills.find(:all)
    give_skill("mralariko", "ContentModerationQueue")
    @n = self.create_some_news
    sym_login :mralariko
    publishing_decisions_count = PublishingDecision.count
    post :deny_content, {
        :id => @n.unique_content.id,
        :deny_reason => 'me molo a mi mismo',
    }
    assert_response :redirect
    assert_equal publishing_decisions_count + 1, PublishingDecision.count
  end

  test "change_authorship_should_work" do
    n = News.find(1)
    assert_equal 1, n.user_id
    sym_login 1
    u2 = User.find(2)
    post :change_authorship, {
        :content_id => n.unique_content.id,
        :login => u2.login,
    }
    assert_response :redirect
    n.reload
    assert_equal 2, n.user_id
  end

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

  test "report no skill" do
    sym_login 1
    assert_raises(AccessDenied) do
      post :report, :id => Content.find(:first).id
    end
  end

  test "report with skill" do
    give_skill(1, "ReportContents")
    sym_login 1
    assert_count_increases(Alert) do
      post :report, :id => Content.find(:first).id
    end
    assert_response :success
  end

  test "report_with_bazar_district_content" do
    give_skill(1, "ReportContents")
    sym_login 1
    assert_count_increases(Alert) do
      post :report, :id => 1113
    end
    assert_response :success
  end

  test "orphaned" do
    sym_login 1
    get :huerfanos
    assert_response :success
  end

  test "close should work with valid reason" do
    sym_login 1
    n = News.find(1)
    assert !n.closed?
    post :close, :id => n.unique_content_id, :reason => 'me caía mal'
    assert_response :redirect
    n.reload
    assert n.closed?
    assert_equal 1, n.closed_by_user.id
    assert 'me caía mal', n.reason_to_close
  end


  test "close shouldn't work with invalid reason" do
    sym_login 1
    n = News.find(1)
    assert !n.closed?
    post :close, :id => n.unique_content_id, :reason => ''
    assert_response :redirect
    n.reload
    assert !n.closed?
  end

  test "tag_content shouldnt work if no skill" do
    sym_login 1
    assert_raises(AccessDenied) do
      post :tag_content, :id => 1, :tags => 'fumanchu se fue a la guerra'
    end
  end

  test "tag_content should work if skill" do
    give_skill(1, "TagContents")
    sym_login 1
    assert_difference("Term.contents_tags.count", 6) do
      post :tag_content, :id => 1, :tags => 'fumanchu se fue a la guerra'
    end
    assert_response :redirect
  end

  test "remove_user_tag shouldnt work if no skill" do
    test_tag_content_should_work_if_skill
    remove_skill(1, "TagContents")

    uct = UsersContentsTag.find(:first, :conditions => ['user_id = 1'])
    sym_login 61
    assert_raises(AccessDenied) do
      post :remove_user_tag, :id => uct.id
    end
  end

  test "remove_user_tag should work if skill" do
    test_tag_content_should_work_if_skill
    sym_login 1
    uct = UsersContentsTag.find(:first, :conditions => ['user_id = 1'])
    assert_count_decreases(ContentsTerm) do
      assert_count_decreases(UsersContentsTag) do
        post :remove_user_tag, :id => uct.id
        assert_response :success
      end
    end
  end

  test "remove_user_tag shouldnt remove others tags" do
    self.test_tag_content_should_work_if_skill
    give_skill(2, "TagContents")
    sym_login 2
    uct = UsersContentsTag.find(:first, :conditions => ['user_id = 1'])
    assert_raises(AccessDenied) do
      post :remove_user_tag, :id => uct.id
    end
  end
end
