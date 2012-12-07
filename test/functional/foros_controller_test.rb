# -*- encoding : utf-8 -*-
require 'test_helper'

class ForosControllerTest < ActionController::TestCase

  test "a topic without forum should return 404" do
    @request.host = "ut.#{App.domain}"
    @topic = Topic.find(1)
    @forum = @topic.terms.find(:first, :conditions => 'taxonomy = \'TopicsCategory\'')
    @forum.unlink(@topic)
    assert_equal 0, @topic.terms.count

    assert_raises(ActiveRecord::RecordNotFound) do
      get :topic, :id => 1
    end
  end

  test "mis_foros" do
    get :mis_foros
    assert_response :success

    sym_login 1
    get :mis_foros
    assert_response :success
  end

  test "faction_banned_user_shouldnt_be_able_to_create_topic" do
    sym_login 1
    f = Faction.find(1)
    fbu = FactionsBannedUser.new(:user_id => 1, :faction_id => f.id, :banner_user_id => 2)
    tc = Term.single_toplevel(:slug => 'ut')
    tcc = tc.children.find(:first, :conditions => "name = 'General' AND taxonomy = 'TopicsCategory'")
    assert fbu.save

    post :create_topic, {:topic => {:title => 'footopic', :main => 'textio'}, :categories_terms => [tcc.id]}
    assert_response :redirect
    assert_not_nil flash[:error]
    assert_equal Cms::DELETED, Topic.find(:first, :order => 'id desc').state
  end

  test "shouldnt_be_able_to_move_it_to_banned_faction" do
    test_should_give_karma_after_creating_topic
    f = Faction.find(1)
    fbu = FactionsBannedUser.new(:user_id => 4, :faction_id => f.id, :banner_user_id => 2)
    assert fbu.save
    tc = Term.single_toplevel(:slug => 'ut')
    tcc = tc.children.find(:first, :conditions => "name = 'General' AND taxonomy = 'TopicsCategory'")
    t = Topic.find(:first, :order => 'id desc')
    assert t.update_attributes(:user_id => 4)
    sym_login 4
    assert_raises(AccessDenied) do
      post :move_topic, :topic => {:id => t.id, :categories_terms => tcc.id}
    end
  end

  test "should_give_karma_after_creating_topic" do
    sym_login 1
    u1 = User.find(1)
    kp = u1.karma_points
    topics = Topic.count
    post :create_topic, {
        :topic => {:title => 'footopic', :main => 'textio'},
        :categories_terms => [
            Term.find(:first, :conditions => 'taxonomy = \'TopicsCategory\'').id]
    }
    assert_response :redirect
    assert_equal topics + 1, Topic.count
    u1.reload
  end

  test "shouldnt_add_to_tracker_if_unselected" do
    sym_login 1
    assert_count_increases(Topic) do
      post :create_topic, {:topic => {:title => 'footopic', :main => 'textio'}, :categories_terms => [Term.find(:first, :conditions => 'taxonomy = \'TopicsCategory\'').id]}
    end
    lt = TrackerItem.find(:first, :order => 'id desc')
    assert !lt.is_tracked?
  end

  test "should_not_show_clans_categories_in_mover_page_from_gm" do
    sym_login 1
    get :edit, :id => 1
    assert_response :success
    assert_nil(@response.body.index('>mapaches<'))
  end

  test "should_not_show_clans_categories_in_mover_page_from_factions_portal" do
    @request.host = 'ut.gamersmafia.com'
    sym_login 1
    get :edit, :id => 1
    assert_response :success
    assert_nil(@response.body.index('>mapaches<'))
  end

  # TODO
  test "should_show_index" do
    get :index
    assert_response :success
  end

  test "should_show_forum_category" do
    get :forum, :id => Term.single_toplevel(:slug => 'ut').id
    assert_response :success
    assert_template 'category'
  end

  test "should_show_forum" do
    get :forum, :id => Term.find(:first, :conditions => 'taxonomy = \'TopicsCategory\'').id
    assert_response :success
    assert_template 'forum'
  end

  test "should_show_topic" do
    sym_login 1
    @request.host = "ut.#{App.domain}"
    get :topic, :id => 1
    assert_response :success, @response.body
  end

  test "should_show_nuevo_topic" do
    sym_login 1
    get :nuevo_topic
    assert_response :success
  end

  test "should_show_nuevo_topic_null_forum_id" do
    sym_login 1
    get :nuevo_topic, :forum_id => nil
    assert_response :success
  end

  test "should_show_edit" do
    sym_login 1
    get :edit, :id => Topic.find(1).id
    assert_response :success
  end

  test "update_topic_should_work" do
    sym_login 1
    t = Topic.find(:first)
    assert_not_equal 'title del topiz', t.title
    post :update_topic, { :topic => { :id => t.id, :main => 'tezto del topic', :title => 'title del topiz'}}
    assert_response :redirect
    t.reload
    assert_equal 'title del topiz', t.title
  end

  test "move_topic_should_work" do
    sym_login 1
    t = Topic.find(1)
    tc2 = t.main_category.root.children.create({:name => 'nombre nueva category', :taxonomy => 'TopicsCategory'})
    assert !tc2.new_record?
    post :move_topic, { :topic => { :id => t.id }, :categories_terms => [tc2.id]}
    assert_response :redirect
    t.reload
    assert_equal tc2.id, t.terms[0].id
  end

  test "create_topic_should_work" do
    sym_login 1
    assert_count_increases(Topic) do
      post :create_topic, {
          :topic => {
              :main => 'tezto del topic',
              :title => 'title del topiz'
          },
          :categories_terms => [
              Term.find(:first, :conditions => "taxonomy = 'TopicsCategory'").id
          ]
      }
    end
    assert_response :redirect
  end

  test "destroy_topic_should_work" do
    sym_login 1
    t1 = Topic.find(1)
    assert_equal Cms::PUBLISHED, t1.state
    post :destroy, { :id => t1.id }
    assert_response :redirect
    t1.reload
    assert_equal Cms::DELETED, t1.state
  end
end
