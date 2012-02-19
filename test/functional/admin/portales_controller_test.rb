require 'test_helper'

class Admin::PortalesControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index ]

  test "should_show_index" do
    get :index, {}, {:user => 1}
    assert_response :success
    assert_template 'index'
  end

  test "should_show_edit" do
    get :editar, {:id => 1}, {:user => 1}
    assert_response :success
    assert_template 'editar'
  end

  test "should_update" do
    t1 = Portal.find(1)
    assert_nil t1.default_gmtv_channel_id
    post :update, {:id => 1, :portal => { :default_gmtv_channel_id => 1 }}, {:user => 1}
    assert_response :redirect
    t1.reload
    assert_not_nil t1.default_gmtv_channel_id
  end
end
