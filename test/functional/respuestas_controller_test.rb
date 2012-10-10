# -*- encoding : utf-8 -*-
require 'test_helper'
require 'test_functional_content_helper'

class RespuestasControllerTest < ActionController::TestCase
  test_common_content_crud :name => 'Question', :form_vars => {:title => 'footapang', :description => "abracadabra"}, :categories_terms => 20



  test "categoria_should_work" do
    get :categoria, :id => 1
    assert_response :success
  end

  def index_should_work_in_portal
    host! "ut.#{App.domain}"
    get :index
    assert_response :success
  end

  test "mejor_respuesta_anon" do
    assert_raises(AccessDenied) { post :mejor_respuesta, :id => 1}
  end

  test "mejor_respuesta_bogus_comment" do
    sym_login 1
    assert_raises(AccessDenied) { post :mejor_respuesta, :id => 1 }
    #  assert_response :redirect
    @q = Question.find(1)
    assert_nil @q.answered_on
  end

  test "sin_respuesta_ok" do
    sym_login 2
    u2 = User.find(2)
    u2.users_skills.create(:role => "EditContents")
    @q = Question.find(1)
    post :sin_respuesta, :id => @q.id
    assert_response :redirect
    assert_nil flash[:error], flash[:error]
    @q.reload
    assert_not_nil @q.answered_on
  end

  test "mejor_respuesta_ok" do
    sym_login 1
    @q = Question.find(1)
    assert @q.unique_content.comments(:conditions => 'deleted = \'f\'').count > 0
    baid = @q.unique_content.comments.find(:first, :conditions => 'deleted = \'f\'').id
    post :mejor_respuesta, :id => baid
    assert_response :redirect
    assert_nil flash[:error], flash[:error]
    @q.reload
    assert_equal baid, @q.accepted_answer_comment_id
  end

  test "revert_mejor_respuesta_ok" do
    test_mejor_respuesta_ok
    assert_not_nil @q.accepted_answer_comment_id
    post :revert_mejor_respuesta, :id => 1
    assert_response :redirect
    @q.reload
    assert_nil @q.accepted_answer_comment_id
  end

  test "update_should_work_if_changing_ammount_and_owner" do
    @q = Question.find(1)
  end

  test "show should work for anon" do
    qfirst = Question.published.find(:first)
    @request.host = host_from_url(Routing.gmurl(qfirst))
    get :show, :id => qfirst.id
    assert_response :success
  end

  test "update_ammount_should_work" do
    @q = Question.find(1)
    Bank.transfer(:bank, @q.user, Question::MIN_AMMOUNT + 1, "ff")
    sym_login @q.user_id
    init = @q.ammount.to_f
    cash = @q.user.cash
    assert cash > Question::MIN_AMMOUNT
    post :update_ammount, { :id => 1, :question => { :ammount => @q.user.cash.to_s } }
    assert_response :redirect
    @q.reload
    assert_equal init + cash, @q.ammount
  end

  test "abiertas_root" do
    get :abiertas, :id => 1
    assert_response :success
  end

  test "abiertas_non_root" do
    t1 = Term.find(1)
    t1c = t1.children.create(:name => 'Especificas', :taxonomy => 'QuestionsCategory')
    get :abiertas, :id => t1c.id
    assert_response :success
  end

  test "cerradas_root" do
    get :cerradas, :id => 1
    assert_response :success
  end

    test "cerradas_non_root" do
    t1 = Term.find(1)
    t1c = t1.children.create(:name => 'Especificas', :taxonomy => 'QuestionsCategory')
    get :cerradas, :id => t1c.id
    assert_response :success
  end

  basic_test :index, :abiertas, :cerradas
end
