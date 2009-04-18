require 'test_helper'

class Admin::ClanesControllerTest < ActionController::TestCase  
  test "index" do
    get :index, {}, {:user => 1}
    assert_response :success
    assert_template 'index'
  end
  
  test "new" do
    get :new, {}, {:user => 1}
    
    assert_response :success
    assert_template 'new'
    
    assert_not_nil assigns(:clan)
  end
  
  test "create" do
    num_clans = Clan.count
    
    post :create, {:clan => {:tag => 'footag', :name => 'fooname'}}, {:user => 1}
    
    assert_response :redirect
    assert_redirected_to :action => 'index'
    
    assert_equal num_clans + 1, Clan.count
  end
  
  test "edit" do
    get :edit, {:id => 1}, {:user => 1}
    
    assert_response :success
    assert_template 'edit'
    
    assert_not_nil assigns(:clan)
    assert assigns(:clan).valid?
  end
  
  test "update" do
    post :update, {:id => 1}, {:user => 1}
    assert_response :redirect
    assert_redirected_to :action => 'edit', :id => 1
  end
  
  test "destroy" do
    assert_not_nil Clan.find(1)
    
    post :destroy, {:id => 1}, {:user => 1}
    assert_response :redirect
    assert_redirected_to "/admin/clanes?page=" # :action => 'index'

    assert Clan.find(1).deleted?
  end
  
  test "should_add_user_to_clans_group" do
    sym_login 1
    @cg = ClansGroup.find(1)
    assert_count_increases(@cg.users) do 
      post :add_user_to_clans_group, { :clans_group_id => @cg.id, :login => 'panzer'}
      assert_response :redirect
    end
  end
  
  test "should_remove_user_from_clans_group" do
    test_should_add_user_to_clans_group
    assert_count_decreases(@cg.users) do 
      post :remove_user_from_clans_group, { :clans_group_id => @cg.id, :user_id => 2}
      assert_response :success
    end
  end
end
