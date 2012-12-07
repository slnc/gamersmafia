# -*- encoding : utf-8 -*-
require 'test_helper'


class CacheObserverRespuestasTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! "ut.#{App.domain}"
  end

  test "should_clear_cache_latest_by_author_on_create" do
    @t = Term.find(1)
    sym_login 'superadmin', 'lalala'
    create_content(
        :question, {
            :title => 'hola mundillo',
            :description => 'iole',
        },
        :root_terms => @t.id)
    @q = Question.find(:first, :order => 'id DESC')
    go_to "respuestas/show/#{@q.id}", 'respuestas/show'
    assert_cache_exists "/#{@t.root.slug}/respuestas/show/latest_by_author_#{@q.user_id}"
  end

  test "should_clear_cache_latest_by_author_on_delete" do
    test_should_clear_cache_latest_by_author_on_create
    delete_content @q
    assert_cache_dont_exist "/#{@t.root.slug}/respuestas/show/latest_by_author_#{@q.user_id}"
  end

  test "should_clear_top_sabios_on_answer" do
    test_should_clear_cache_latest_by_author_on_create
    assert_cache_exists "/ut/respuestas/top_sabios/"
    sym_login 'panzer', 'lelele'
    post_comment_on @q
    sym_login 'superadmin', 'lalala'
    comment = Comment.find(:first, :order => 'id DESC')
    post 'mejor_respuesta', :id => comment.id
    assert_cache_dont_exist "/ut/respuestas/top_sabios/"
  end

  test "should_clear_top_sabios_on_answer_category" do
    test_should_clear_cache_latest_by_author_on_create
    cat_id = @q.terms.first.root_id
    go_to "respuestas/categoria/#{cat_id}", 'respuestas/index'
    assert_cache_exists "/common/respuestas/top_sabios/#{cat_id}"
    post_comment_on @q
    comment = Comment.find(:first, :order => 'id DESC')
    post 'mejor_respuesta', :id => comment.id
    assert_cache_dont_exist "/common/respuestas/top_sabios/#{cat_id}"
  end


  def teardown
    ActionController::Base.perform_caching             = false
  end
end
