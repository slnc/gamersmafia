require File.dirname(__FILE__) + '/../../test_helper'

class Admin::AdsSlotsControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :new, :edit, :update, :destroy ]
  
  def test_index
    sym_login 1
    get :index
    assert_response :success
  end
  
  def test_new
    sym_login 1
    get :index
    assert_response :success
  end
  
  def test_create
    sym_login 1
    assert_count_increases(AdsSlot) do
      post :create, { :ads_slot => { :name => 'fourling', :location => 'bottom', :behaviour_class => 'Random'}}
    end
    assert_response :redirect
  end
  
  def test_edit
    test_create
    get :edit, :id => AdsSlot.find(:first).id
    assert_response :success
  end
  
  def test_update
    test_create
    
    post :update, { :id => AdsSlot.find(:first, :order => 'id DESC').id, :ads_slot => { :name => 'fourling2'}}
    
    assert_response :redirect
    assert_equal 'fourling2', AdsSlot.find(:first, :order => 'id desc').name
  end
  
  def test_update_slots_instances
    test_create
    a_a = Ad.create(:name => 'foo', :html => 'flick')
    a_b = Ad.create(:name => 'bar', :html => 'flock')
    ainst = AdsSlotsInstance.count
    as = AdsSlot.find(:first)
    post :update_slots_instances, {:id => as.id, :ads => [a_a.id, a_b.id]}
    assert_response :redirect
    assert_equal ainst + 2, AdsSlotsInstance.count    
  end
  
  def test_add_to_portal
    test_create
    @as = AdsSlot.find(:first)
    p_size = @as.portals.size
    post :add_to_portal, :id => @as.id, :portal_id => -1
    assert_equal p_size + 1, @as.portals.size 
    assert_response :redirect
  end
  
  def test_add_to_portal2
    test_create
    @as = AdsSlot.find(:first)
    p_size = @as.portals.size
    post :add_to_portal, :id => @as.id, :portal_id => 1
    assert_equal p_size + 1, @as.portals.size   
    assert @as.portals[0].kind_of?(Portal)
    assert_equal 1, @as.portals[0].id
    assert_response :redirect
  end
  
  def test_remove_from_portal
    test_add_to_portal
    p_size = @as.portals.size
    post :remove_from_portal, :id => @as.id, :portal_id => -1
    assert_equal p_size - 1, @as.portals.size
    assert_response :redirect
  end
  
  def test_copy
    test_create
    @as = AdsSlot.find(:first)
    post :copy, { :id => @as.id, :ads_slot => { :name => 'laskjalkdsad' } }
    puts @response.flash[:error]
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
