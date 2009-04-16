require 'test_helper'

class Admin::EntradasfaqControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :new, :show, :create, :edit, :update, :destroy ]
  
  def test_index
    get :index, {}, {:user => 1}
    assert_response :success
    assert_template 'index'
  end
  
  def test_new
    get :new, {}, {:user => 1}
    
    assert_response :success
    assert_template 'new'
    
    assert_not_nil assigns(:faq_entry)
  end
  
  def test_create
    num_faq_entries = FaqEntry.count
    
    post :create, {:faq_entry => {:question => 'foo?', :answer => 'bar', :faq_category_id => 1}}, {:user => 1}
    
    assert_response :redirect
    assert_redirected_to :action => 'index'
    
    assert_equal num_faq_entries + 1, FaqEntry.count
  end
  
  def test_edit
    get :edit, {:id => 1}, {:user => 1}
    
    assert_response :success
    assert_template 'edit'
    
    assert_not_nil assigns(:faq_entry)
    assert assigns(:faq_entry).valid?
  end
  
  def test_update
    post :update, {:id => 1}, {:user => 1}
    assert_response :redirect
    assert_redirected_to :action => 'edit', :id => 1
  end
  
  def test_destroy
    assert_not_nil FaqEntry.find(1)
    
    post :destroy, {:id => 1}, {:user => 1}
    assert_response :redirect
    assert_redirected_to :action => 'index'
    
    assert_raise(ActiveRecord::RecordNotFound) {
      FaqEntry.find(1)
    }
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
  
  def test_should_moveup_faq_Entry
    test_create
    assert_count_increases(FaqEntry) do post :create, {:faq_entry => {:faq_category_id => 1, :question => 'barrrr', :answer => 'bubaluu'}} end
    fc = FaqEntry.find(:first, :order => 'id desc')
    orig_pos = fc.position
    post :moveup, {:id => fc.id}
    assert_response :redirect
    fc.reload
    assert fc.position < orig_pos
  end
  
  def test_should_movedown_faq_Entry
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
