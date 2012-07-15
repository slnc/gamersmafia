# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::AdsSlotsControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :new, :edit, :update, :destroy ]

  test "index" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "new" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "create" do
    sym_login 1
    assert_count_increases(AdsSlot) do
      post :create, { :ads_slot => { :name => 'fourling', :location => 'bottom', :behaviour_class => 'Random'}}
    end
    assert_response :redirect
  end

  test "edit" do
    test_create
    get :edit, :id => AdsSlot.find(:first).id
    assert_response :success
  end

  test "update" do
    test_create

    post :update, { :id => AdsSlot.find(:first, :order => 'id DESC').id, :ads_slot => { :name => 'fourling2'}}

    assert_response :redirect
    assert_equal 'fourling2', AdsSlot.find(:first, :order => 'id desc').name
  end

  test "update_slots_instances" do
    test_create
    a_a = Ad.create(:name => 'foo', :html => 'flick')
    a_b = Ad.create(:name => 'bar', :html => 'flock')
    ainst = AdsSlotsInstance.count
    as = AdsSlot.find(:first)
    post :update_slots_instances, {:id => as.id, :ads => [a_a.id, a_b.id]}
    assert_response :redirect
    assert_equal ainst + 2, AdsSlotsInstance.count
  end

  test "add_to_portal" do
    test_create
    @as = AdsSlot.find(:first)
    p_size = @as.portals.size
    post :add_to_portal, :id => @as.id, :portal_id => -1
    assert_equal p_size + 1, @as.portals.size
    assert_response :redirect
  end

  test "add_to_portal2" do
    test_create
    @as = AdsSlot.find(:first)
    p_size = @as.portals.size
    post :add_to_portal, :id => @as.id, :portal_id => 1
    assert_equal p_size + 1, @as.portals.size
    assert @as.portals[0].kind_of?(Portal)
    assert_equal 1, @as.portals[0].id
    assert_response :redirect
  end

  test "remove_from_portal" do
    test_add_to_portal
    p_size = @as.portals.size
    post :remove_from_portal, :id => @as.id, :portal_id => -1
    assert_equal p_size - 1, @as.portals.size
    assert_response :redirect
  end

  test "copy" do
    test_create
    @as = AdsSlot.find(:first)
    post :copy, { :id => @as.id, :ads_slot => { :name => 'laskjalkdsad' } }
    assert_response :redirect
    @as2 = AdsSlot.find(:first, :order => 'id desc')
    assert_equal @as.behaviour_class, @as2.behaviour_class
    assert_equal @as.location, @as2.location
    assert @as2.position != @as.position
    @as2.ads.each do |ad|
      assert @as2.ads.find(:first, :conditions => ['ads.id = ?', ad.id])
    end
  end
end
