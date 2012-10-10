# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::CategoriasfaqControllerTest < ActionController::TestCase

  test "index no skill" do
    sym_login 1
    assert_raises(AccessDenied) do
      get :index
    end
  end

  test "index" do
    give_skill(1, "EditFaq")
    sym_login 1
    get :index
    assert_response :success
    assert_template 'index'
  end

  test "new" do
    give_skill(1, "EditFaq")
    sym_login 1
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:faq_category)
  end

  test "create" do
    give_skill(1, "EditFaq")
    sym_login 1
    num_faq_categories = FaqCategory.count

    assert_difference("FaqCategory.count") do
      post :create, {:faq_category => {:name => 'fooooooo'}}
    end

    assert_response :redirect
    assert_redirected_to :action => 'index'
  end

  test "edit" do
    give_skill(1, "EditFaq")
    sym_login 1
    get :edit, {:id => 1}

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:faq_category)
    assert assigns(:faq_category).valid?
  end

  test "update" do
    give_skill(1, "EditFaq")
    sym_login 1
    post :update, {:id => 1}
    assert_response :redirect
    assert_redirected_to :action => 'edit', :id => 1
  end

  test "destroy" do
    give_skill(1, "EditFaq")
    sym_login 1
    assert_not_nil FaqCategory.find(1)

    post :destroy, {:id => 1}
    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_raise(ActiveRecord::RecordNotFound) do
      FaqCategory.find(1)
    end
  end

  test "should_moveup_faq_category" do
    test_create
    assert_count_increases(FaqCategory) do
      post :create, {:faq_category => {:name => 'barrrr'}}
    end
    fc = FaqCategory.find(:first, :order => 'id desc')
    orig_pos = fc.position
    post :moveup, {:id => fc.id}
    assert_response :redirect
    fc.reload
    assert fc.position < orig_pos
  end

  test "should_movedown_faq_category" do
    test_create
    assert_count_increases(FaqCategory) do
      post :create, {:faq_category => {:name => 'barrrr'}}
    end
    fc = FaqCategory.find(:first, :order => 'id asc')
    orig_pos = fc.position
    post :movedown, {:id => fc.id}
    assert_response :redirect
    fc.reload
    assert fc.position > orig_pos
  end
end
