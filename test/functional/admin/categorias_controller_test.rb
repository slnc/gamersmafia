require File.dirname(__FILE__) + '/../../test_helper'

class Admin::CategoriasControllerTest < ActionController::TestCase
  
  def test_index_in_gm
    get :index, {}, {:user => 1}
    assert_response :success
    assert_template 'index'
  end
  
  def test_index_with_type_in_gm
    get :index, {:type_name => 'Image'}, {:user => 1}
    assert_response :success
    assert_template 'index'
  end
  
  def test_new_in_gm
    get :categorias_new, {:type_name => 'Topic' }, {:user => 1}
    
    assert_response :success
    assert_template 'categorias_new'
    
    assert_not_nil assigns(:category)
  end
  
  def test_create_in_gm
    num_topics_category = TopicsCategory.count
    
    post :categorias_create, {:type_name => 'Topic', :category => {:name => 'foo_forum', :code => 'foo_code'}}, {:user => 1}
    assert_response :redirect, @response.body
    assert_redirected_to "/admin/categorias/Topic"
    
    assert_equal num_topics_category + 1, TopicsCategory.count
  end
  
  def test_edit_in_gm
    get :categorias_edit, {:type_name => 'Topic', :id => 1}, {:user => 1}
    
    assert_response :success
    assert_template 'categorias_edit'
    
    assert_not_nil assigns(:category)
    assert assigns(:category).valid?
  end
  
  def test_edit_in_gm_by_capo
    u10 = User.find(10)
    u10.give_admin_permission(:bazar_manager)
    get :categorias_edit, {:type_name => 'Image', :id => 1}, {:user => 10}
    
    assert_response :success
    assert_template 'categorias_edit'
    
    assert_not_nil assigns(:category)
    assert assigns(:category).valid?
  end
  
  def test_update_in_gm
    post :categorias_update, {:type_name => 'Topic', :id => 1}, {:user => 1}
    assert_response :redirect
    assert_redirected_to "/admin/categorias/Topic/edit/1"
  end
  
  def test_destroy_confirm_in_gm
    assert_not_nil TopicsCategory.find(1)
    
    post :category_destroy_confirm, {:type_name => 'Topic', :id => 1}, {:user => 1}
    assert_response :redirect
    assert_redirected_to "/admin/categorias/Topic"
    
    assert_raise(ActiveRecord::RecordNotFound) {
      TopicsCategory.find(1)
    }
  end
  
  def test_index_with_type_in_clan
    portal = ClansPortal.find(:first)
    test_index_with_type_in_gm
  end
  
  def test_index_in_clan
    portal = ClansPortal.find(:first)
    test_index_in_gm
  end
  
  def test_new_in_clan
    portal = ClansPortal.find(:first)
    test_new_in_gm
  end
  
  # TODO
  #  def test_create_root_catoegry_in_clan_fails
  #    portal = ClansPortal.find(:first)
  #    num_topics_category = TopicsCategory.count
  #    
  #    assert_raises(AccessDenied) do
  #      post :categorias_create, {:type_name => 'Topic', :category => {:name => 'foo_forum', :code => 'foo_code'}}, {:user => 1}
  #    end
  #  end
  
  def test_create_nonroot_catoegry_in_clan_passes
    portal = ClansPortal.find(:first)
    num_topics_category = TopicsCategory.count
    post :categorias_create, {:type_name => 'Topic', :category => {:name => 'foo_forum', :code => 'foo_code', :parent_id => TopicsCategory.find(:first, :conditions => 'clan_id is not null').id}}, {:user => 1}
    assert_response :redirect, @response.body
    assert_redirected_to "/admin/categorias/Topic"
    
    assert_equal num_topics_category + 1, TopicsCategory.count    
  end
end
