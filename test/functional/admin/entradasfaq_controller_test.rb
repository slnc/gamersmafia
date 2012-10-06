# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::EntradasfaqControllerTest < ActionController::TestCase

  test "index no skill" do
    sym_login 1
    assert_raises(AccessDenied) do
      get :index
    end
  end

  test "index with skill" do
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

    assert_not_nil assigns(:faq_entry)
  end

  test "create" do
    give_skill(1, "EditFaq")
    sym_login 1
    assert_difference("FaqEntry.count") do
      post :create, {:faq_entry => {:question => 'foo?', :answer => 'bar', :faq_category_id => 1}}
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

    assert_not_nil assigns(:faq_entry)
    assert assigns(:faq_entry).valid?
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

    assert_not_nil FaqEntry.find(1)

    post :destroy, {:id => 1}
    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_raise(ActiveRecord::RecordNotFound) {
      FaqEntry.find(1)
    }
  end

  test "should_moveup_faq_Entry" do
    test_create
    assert_count_increases(FaqEntry) do post :create, {:faq_entry => {:faq_category_id => 1, :question => 'barrrr', :answer => 'bubaluu'}} end
    fc = FaqEntry.find(:first, :order => 'id desc')
    orig_pos = fc.position
    post :moveup, {:id => fc.id}
    assert_response :redirect
    fc.reload
    assert fc.position < orig_pos
  end

  test "should_movedown_faq_Entry" do
    test_create
    assert_count_increases(FaqEntry) do post :create, {:faq_entry => {:faq_category_id => 1, :question => 'barrrr', :answer => 'bubaluu'}} end
    fc = FaqEntry.find(:first, :order => 'id asc')
    orig_pos = fc.position
    post :movedown, {:id => fc.id}
    assert_response :redirect
    fc.reload
    assert fc.position > orig_pos
  end

end
