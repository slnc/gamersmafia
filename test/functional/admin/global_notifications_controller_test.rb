require 'test_helper'

class Admin::GlobalNotificationsControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :new, :edit ]
  
  test "index" do
    sym_login 1
    get :index
    assert_response :success
  end
  
  test "new" do
    sym_login 1
    get :new
    assert_response :success
  end
  
  test "create" do
    test_new
    assert_count_increases(GlobalNotification) do
      post :create, { :global_notification => { :title => "Mensaje global", :main => "Texto del main", :recipient_type => GlobalNotification::VALID_RECIPIENT_TYPES[0]}}
      assert_response :redirect, @response.flash[:error]
      @gn = GlobalNotification.find(:first, :order => 'id DESC')
    end
  end
  
  test "edit" do
    test_create
    get :edit, :id => @gn.id
    assert_response :success
  end
  
  test "update" do
    test_create
    post :update, :id => @gn.id, :global_notification => { :title => "Title 2"}
    assert_response :redirect
    @gn.reload
    assert_equal "Title 2", @gn.title
  end
  
  test "confirm" do
    test_create
    assert !@gn.confirmed
    post :confirm, :id => @gn.id
    @gn.reload
    assert_response :redirect
    assert @gn.confirmed 
  end
end
