require File.dirname(__FILE__) + '/../test_helper'


class CacheObserverRespuestasTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! "ut.#{App.domain}"
  end

  # COMMON
  def test_should_clear_cache_latest_by_author
    t = Term.find(1).children.find_by_taxonomy('QuestionsCategory')
    sym_login 'superadmin', 'lalala'
    create_content :question, {:title => 'hola mundillo', :description => 'iole'}, :categories_terms => t.id
    q = Question.find(:first, :order => 'id DESC')
    go_to "respuestas/show/#{q.id}", 'respuestas/show'
    assert_cache_exists "/#{t.root.slug}/respuestas/show/latest_by_author_#{q.user_id}"
    delete_content q
    assert_cache_dont_exist "/#{t.root.slug}/respuestas/show/latest_by_author_#{q.user_id}"
  end

  def teardown
    ActionController::Base.perform_caching             = false
  end
end
