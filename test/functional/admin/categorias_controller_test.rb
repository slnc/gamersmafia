require File.dirname(__FILE__) + '/../../test_helper'

class Admin::CategoriasControllerTest < ActionController::TestCase
  
  def test_index_no_perm
    sym_login 2
    assert_raises(AccessDenied) { get :index }
  end
  
  def test_index_capo
    u2 = User.find(2)
    u2.give_admin_permission(:capo)
    sym_login 2
    get :index
    assert_response :success
  end
  
  def test_index_boss
    u2 = User.find(2)
    Faction.find(1).update_boss(u2)
    sym_login 2
    get :index
    assert_response :success
  end
  
  def test_index_editor
    u2 = User.find(2)
    f1 = Faction.find(1)
    f1.add_editor(u2, ContentType.find(:first))
    sym_login 2
    get :index
    assert_response :success
  end
  
  def test_index_don
    u2 = User.find(2)
    bd1 = BazarDistrict.find(1)
    bd1.update_don(u2)
    sym_login 2
    get :index
    assert_response :success
  end
  
  def test_index_sicario
    u2 = User.find(2)
    bd1 = BazarDistrict.find(1)
    bd1.add_sicario(u2)
    sym_login 2
    get :index
    assert_response :success
  end
  
  def test_hijos_if_perm
    u2 = User.find(2)
    u2.give_admin_permission(:capo)
    sym_login 2
    get :hijos, :id => 1, :content_type => 'News'
  end
  
  def test_hijos_if_no_perm
    u2 = User.find(2)
    sym_login 2
    assert_raises(AccessDenied) { get :hijos, :id => 1, :content_type => 'Topic' }    
  end
  
  def test_hijos_if_boss_but_no_perm
    u2 = User.find(2)
    Faction.find(1).update_boss(u2)
    
    sym_login 2
    assert_raises(AccessDenied) do
      get :hijos, :id => 5, :content_type => 'Topic' # anime
    end 
  end
  
  def test_contenidos_if_perm
    u2 = User.find(2)
    u2.give_admin_permission(:capo)
    sym_login 2
    get :contenidos, :id => 1, :content_type => 'Topic'  
  end
  
  def test_contenidos_if_no_perm
    u2 = User.find(2)
    Faction.find(1).update_boss(u2)
    
    sym_login 2
    assert_raises(AccessDenied) { get :contenidos, :id => 5, :content_type => 'Topic' } # anime 
  end
  
  def test_cant_create_root_level_blank_taxonomy_term
    u2 = User.find(2)
    u2.give_admin_permission(:capo)
    
    sym_login 2
    assert_raises(AccessDenied) do
      post :create, :term => { :name => 'furrinori', :taxonomy => ''}
    end
  end
  
  
  def test_create_if_perm
    u2 = User.find(2)
    Faction.find(1).update_boss(u2)
    
    sym_login 2
    assert_count_increases(Term) do
      post :create, :term => { :name => 'furrinori', :taxonomy => 'TopicsCategory', :parent_id => 1}
      assert_response :redirect
    end
    
    @t = Term.find(:first, :order => 'id DESC')
    assert_equal 'furrinori', @t.name
    assert_equal 'TopicsCategory', @t.taxonomy
    assert_equal 1, @t.parent_id
  end
  
  def test_create_if_no_perm
    u2 = User.find(2)
    Faction.find(1).update_boss(u2)
    
    sym_login 2
    
    assert_raises(AccessDenied) do
      post :create, :term => { :name => 'furrinori', :taxonomy => 'TopicsCategory', :parent_id => 5}
    end
  end
  
  def test_update_if_perm
    test_create_if_perm
    post :update, :id => @t.id, :term => { :name => 'furrinori2' }
    assert_response :redirect
    @t.reload
    assert_equal 'furrinori2', @t.name
  end
  
  def test_update_if_no_perm
    test_create_if_perm
    sym_login 3
    assert_raises(AccessDenied) do
      post :update, :id => @t.id, :term => { :name => 'furrinori2' }
    end
  end
  
  def test_mass_move_if_perm
    test_create_if_perm
    n = Topic.find(:first)
    assert_count_increases(ContentsTerm) { @t.link(n.unique_content) }
    post :mass_move, :id => @t.id, :destination_term_id => 17, :content_type => 'Topic', :contents => [n.unique_content.id]
    assert_response :redirect
    assert_equal 0, @t.find(:all, :content_type => 'Topic', :conditions => ['contents.id = ?', n.unique_content_id]).size
    t17 = Term.find(17)
    assert_equal 1, t17.find(:all, :content_type => 'Topic', :conditions => ['contents.id = ?', n.unique_content_id]).size
  end
  
  def test_mass_move_if_no_perm
    test_create_if_perm
    n = Topic.find(:first)
    t = Term.single_toplevel(:slug => 'deportes').children.create(:name => 'general', :taxonomy => 'TopicsCategory')
    # assert_count_increases(ContentsTerm) { @t.link(n.unique_content) }
    assert_raises(AccessDenied) do
      post :mass_move, :id => t.id, :destination_term_id => 5, :content_type => 'Topic', :contents => [n.unique_content.id]
    end
  end
  
  def test_destroy_if_perm
    test_create_if_perm
    post :destroy, :id => @t.id
    assert_response :redirect
    assert_nil Term.find_by_id(@t.id)
  end
  
  def test_destroy_if_no_perm
    test_create_if_perm
    sym_login 3
    assert_raises(AccessDenied) do
      post :destroy, :id => @t.id
    end  
  end
  
  def test_destroy_if_perm_but_not_empty
    test_create_if_perm
    n = Topic.find(:first)
    assert_count_increases(ContentsTerm) { @t.link(n.unique_content) }
    post :destroy, :id => @t.id
    assert_response :redirect
    assert Term.find_by_id(@t.id)
  end
  
  
  
  
  
  
  def atest_index_in_gm
    get :index, {}, {:user => 1}
    assert_response :success
    assert_template 'index'
  end
  
  def atest_index_with_type_in_gm
    get :index, {:type_name => 'Image'}, {:user => 1}
    assert_response :success
    assert_template 'index'
  end
  
  def atest_new_in_gm
    get :categorias_new, {:type_name => 'Topic' }, {:user => 1}
    
    assert_response :success
    assert_template 'categorias_new'
    
    assert_not_nil assigns(:category)
  end
  
  def atest_create_in_gm
    num_topics_category = TopicsCategory.count
    
    post :categorias_create, {:type_name => 'Topic', :category => {:name => 'foo_forum', :code => 'foo_code'}}, {:user => 1}
    assert_response :redirect, @response.body
    assert_redirected_to "/admin/categorias/Topic"
    
    assert_equal num_topics_category + 1, TopicsCategory.count
  end
  
  def atest_edit_in_gm
    get :categorias_edit, {:type_name => 'Topic', :id => 1}, {:user => 1}
    
    assert_response :success
    assert_template 'categorias_edit'
    
    assert_not_nil assigns(:category)
    assert assigns(:category).valid?
  end
  
  def atest_edit_in_gm_by_capo
    u10 = User.find(10)
    u10.give_admin_permission(:bazar_manager)
    get :categorias_edit, {:type_name => 'Image', :id => 1}, {:user => 10}
    
    assert_response :success
    assert_template 'categorias_edit'
    
    assert_not_nil assigns(:category)
    assert assigns(:category).valid?
  end
  
  def atest_update_in_gm
    post :categorias_update, {:type_name => 'Topic', :id => 1}, {:user => 1}
    assert_response :redirect
    assert_redirected_to "/admin/categorias/Topic/edit/1"
  end
  
  def atest_destroy_confirm_in_gm
    assert_not_nil TopicsCategory.find(1)
    
    post :category_destroy_confirm, {:type_name => 'Topic', :id => 1}, {:user => 1}
    assert_response :redirect
    assert_redirected_to "/admin/categorias/Topic"
    
    assert_raise(ActiveRecord::RecordNotFound) {
      TopicsCategory.find(1)
    }
  end
  
  def atest_index_with_type_in_clan
    portal = ClansPortal.find(:first)
    test_index_with_type_in_gm
  end
  
  def atest_index_in_clan
    portal = ClansPortal.find(:first)
    test_index_in_gm
  end
  
  def atest_new_in_clan
    portal = ClansPortal.find(:first)
    test_new_in_gm
  end
  
  # TODO
  #  def atest_create_root_catoegry_in_clan_fails
  #    portal = ClansPortal.find(:first)
  #    num_topics_category = TopicsCategory.count
  #    
  #    assert_raises(AccessDenied) do
  #      post :categorias_create, {:type_name => 'Topic', :category => {:name => 'foo_forum', :code => 'foo_code'}}, {:user => 1}
  #    end
  #  end
  
  def atest_create_nonroot_catoegry_in_clan_passes
    portal = ClansPortal.find(:first)
    num_topics_category = TopicsCategory.count
    post :categorias_create, {:type_name => 'Topic', :category => {:name => 'foo_forum', :code => 'foo_code', :parent_id => TopicsCategory.find(:first, :conditions => 'clan_id is not null').id}}, {:user => 1}
    assert_response :redirect, @response.body
    assert_redirected_to "/admin/categorias/Topic"
    
    assert_equal num_topics_category + 1, TopicsCategory.count    
  end
end
