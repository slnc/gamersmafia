# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::AdsSlotsControllerTest < ActionController::TestCase

  test "index no skill" do
    sym_login 2
    assert_raises(AccessDenied) do
      get :index
    end
    assert_response :success
  end

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
    assert_difference("AdsSlot.count") do
      post :create, {
          :ads_slot => {
              :name => 'fourling',
              :location => 'bottom',
              :behaviour_class => 'Random',
          },
      }
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
