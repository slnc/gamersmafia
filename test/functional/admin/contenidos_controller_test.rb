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

  test "mass_moderate_should_work_if_mass_approve" do
    n = self.create_some_news
    Content.send_draft_to_moderation_queue(n)
    n.reload
    assert_equal Cms::PENDING, n.state
    u61 = User.find(61)
    assert_difference("u61.users_skills.count") do
      u61.users_skills.create(:role => "MassModerateContents")
    end
    sym_login 61
    post :mass_moderate, {
        :mass_action => 'publish',
        :items => [n.unique_content.id],
    }
    assert_response :redirect
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
    t = Term.create({:taxonomy => "ContentsTag", :name => "fumanchu"})
    sym_login 1
    assert_difference("UsersContentsTag.count", 1) do
      post :tag_content, :id => 1, :tags => "#{t.id},"
    end
    assert_response :redirect
  end

  test "remove_user_tag shouldnt work if no skill" do
    Term.create(:taxonomy => "TagContents", :name => "fumanchu")
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
