require File.dirname(__FILE__) + '/../../test_helper'

class Admin::CategoriasfaqControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :new, :create, :edit, :update, :destroy ]
  
  def test_index
    get :index, {}, {:user => 1}
    assert_response :success
    assert_template 'index'
  end
  
  def test_new
    get :new, {}, {:user => 1}
    
    assert_response :success
    assert_template 'new'
    
    assert_not_nil assigns(:faq_category)
  end
  
  def test_create
    sym_login 1
    num_faq_categories = FaqCategory.count
    
    post :create, {:faq_category => {:name => 'fooooooo'}}
    
    assert_response :redirect
    assert_redirected_to :action => 'index'
    
    assert_equal num_faq_categories + 1, FaqCategory.count
  end
  
  def test_edit
    get :edit, {:id => 1}, {:user => 1}
    
    assert_response :success
    assert_template 'edit'
    
    assert_not_nil assigns(:faq_category)
    assert assigns(:faq_category).valid?
  end
  
  def test_update
    post :update, {:id => 1}, {:user => 1}
    assert_response :redirect
    assert_redirected_to :action => 'edit', :id => 1
  end
  
  def test_destroy
    assert_not_nil FaqCategory.find(1)
    
    post :destroy, {:id => 1}, {:user => 1}
    assert_response :redirect
    assert_redirected_to :action => 'index'
    
    assert_raise(ActiveRecord::RecordNotFound) {
      FaqCategory.find(1)
    }
  end
  
  def test_should_moveup_faq_category
    test_create
    assert_count_increases(FaqCategory) do post :create, {:faq_category => {:name => 'barrrr'}} end
    fc = FaqCategory.find(:first, :order => 'id desc')
    orig_pos = fc.position
    post :moveup, {:id => fc.id}
    assert_response :redirect
    fc.reload
    assert fc.position < orig_pos
  end
  
  def test_should_movedown_faq_category
    test_create
    assert_count_increases(FaqCategory) do post :create, {:faq_category => {:name => 'barrrr'}} end
    fc = FaqCategory.find(:first, :order => 'id asc')
    orig_pos = fc.position
    post :movedown, {:id => fc.id}
    assert_response :redirect
    fc.reload
    assert fc.position > orig_pos
  end
  
  def test_user_with_admin_permission_should_allow_if_registered
    assert_raises(AccessDenied) { get :index }
    u2 = User.find(2)
    sym_login u2
    assert_raises(AccessDenied) { get :index }
    
    u2.give_admin_permission(:faq)
    
    sym_login u2
    get :index
    assert_response :success
  end
end
