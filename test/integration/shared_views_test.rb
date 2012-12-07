# -*- encoding : utf-8 -*-
require 'test_helper'

class SharedViewsTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  def create_news
    faction_host FactionsPortal.find_by_code('ut')
    get '/site' # para cargar request
    already_logged_in = (not request.session.nil? and not request.session[:user].nil?)
    sym_login('superadmin', 'lalala') unless already_logged_in
    post "/noticias/create", {
      :news => { :title => 'titulito', :description => 'fo' },
      :root_terms => [1],
    }
    assert_response :redirect, @response.body
    n = News.find(:first, :order => 'id DESC')
    Content.publish_content_directly(n, User.find(1))
    n.reload
    assert_equal Cms::PUBLISHED, n.state
    logout unless already_logged_in
    n
  end

  def create_comments(obj, number_of_comments)
    get '/site' # para cargar request
    already_logged_in = (not request.session.nil? and not request.session[:user].nil?)
    sym_login('superadmin', 'lalala') unless already_logged_in
    uniq = obj
    i_count = obj.cache_comments_count

    base = i_count
    number_of_comments.times do |i|
      post "/comments/create", { :comment => {:comment => "Comentario #{i_count + i + 1}", :content_id => uniq.id}, :redirto => '/foo' }
      c = Comment.find(:first, :order => 'id ASC')
      assert_response :redirect
    end
    # Kernel.sleep 1

    logout unless already_logged_in
  end

  test "should_show_first_page_to_anonymous_users" do
    Cms.comments_per_page = 1
    n = create_news
    Term.single_toplevel(:slug => 'gm').link(n)
    create_comments n, 2
    get "/noticias/show/#{n.id}"
    assert_response :success
    assert /Comentario 1/ =~ @response.body
    Cms.comments_per_page = 30
  end

  test "should_show_first_page_of_unread_comments_for_registered_user_when_user_hasnt_read_the_content" do
    sym_login('superadmin', 'lalala')
    Cms.comments_per_page = 1
    n = create_news
    Term.single_toplevel(:slug => 'gm').link(n)
    create_comments n, 3
    get "/noticias/show/#{n.id}"
    assert_response :success
    assert /Comentario 1/ =~ @response.body
    Cms.comments_per_page = 30
  end

  test "should_show_first_page_of_unread_comments_for_registered_user_when_user_has_read_the_content_but_only_the_first_comment" do
    sym_login('superadmin', 'lalala')
    Cms.comments_per_page = 2
    n = create_news
    create_comments n, 1
    Term.single_toplevel(:slug => 'gm').link(n)
    # User.db_query("UPDATE comments set created_on = created_on - '5 minutes'::interval where id = (SELECT max(id) FROM comments)")

    get "/noticias/show/#{n.id}"
    assert_response :success, @response.body
    assert /Comentario 1/ =~ @response.body
    # User.db_query("UPDATE tracker_items SET lastseen_on = lastseen_on - '4 minutes'::interval WHERE content_id = #{n.id} AND user_id = #{request.session[:user]}") # set created_on = now() - '5 minutes'::interval where id = #{c.id}")
    create_comments n, 2
#    User.db_query("UPDATE comments set created_on = created_on - '2 minutes'::interval where id IN (SELECT id FROM comments ORDER BY id DESC LIMIT 2)")
    # Kernel.sleep 1

    get "/noticias/show/#{n.id}"
    assert_response :success
    assert /Comentario 2/ =~ @response.body
    Cms.comments_per_page = 30
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end

