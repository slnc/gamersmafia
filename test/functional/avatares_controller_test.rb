# -*- encoding : utf-8 -*-
require 'test_helper'

class AvataresControllerTest < ActionController::TestCase

  test "should_show_index" do
    assert_raises(AccessDenied) { get :index }
    sym_login 1
    get :index
    assert_response :success
  end

  test "should_show_factions_avatars_overview" do
    sym_login 1
    get :factions_avatars_overview
    assert_response :success
  end

  test "should_show_list" do
    sym_login 1
    get :list, { :mode => 'clan'}
    assert_response :success
  end

  test "faction_should_work" do
    sym_login 1
    get :faction, { :id => 1}
    assert_response :success
  end

  test "new_should_work" do
    sym_login 1
    get :new
    assert_response :success
  end

  test "create_from_zip_should_work" do
    sym_login 1
    a_count = Avatar.count
    post :create_from_zip, { :avatar => fixture_file_upload('files/5avatars_from.zip', 'application/zip')}
    assert_response :redirect
    assert_equal a_count + 5, Avatar.count
  end

  test "create_should_work" do
    sym_login 1
    assert_count_increases(Avatar) do
      post :create, { :avatar => { :name => 'buddha', :submitter_user_id => 1, :path => fixture_file_upload('files/buddha.jpg', 'image/jpeg')}}
    end
    assert_response :redirect
  end

  test "edit_should_work" do
    sym_login 1
    get :edit, { :id => 1}
    assert_response :success
  end

  test "update_should_work" do
    sym_login 1
    post :update, { :id => 1, :avatar => { :path => fixture_file_upload('files/buddha.jpg', 'image/jpeg')}}
    assert_response :redirect
    assert Avatar.find(1).path.include?('buddha.jpg')
  end

  test "destroy_should_work" do
    sym_login 1
    assert_count_decreases(Avatar) do
      post :destroy, { :id => 1}
    end
    assert_response :redirect
  end

  test "destroy_returning_should_work" do
    sym_login 1
    %w(SoldUserAvatar SoldFactionAvatar SoldClanAvatar).each do |cls|
      Avatar.create(:name => 'pincho', :submitter_user_id => 1, :faction_id => 1, :level => 0) if Avatar.find_by_id(1).nil?
      u1 = User.find(1)
      cash = u1.cash

      prod = Product.find_by_cls(cls)
      price_paid = prod.price
      assert_count_increases(SoldProduct) do
        Object.const_get(cls).create(:user_id => 1, :price_paid => price_paid, :used => true, :product_id =>  prod.id)
      end
      # necesario porque no estamos comprando el producto realmente
      opts = {}
      if cls == 'SoldClanAvatar'
        opts[:faction_id] = nil
        opts[:clan_id] = 1
      end
      if cls == 'SoldFactionAvatar'
        opts[:faction_id] = 1
        opts[:clan_id] = nil
      end
      if cls == 'SoldUserAvatar'
        opts[:faction_id] = nil
        opts[:clan_id] = nil
      end

      assert Avatar.find(Avatar.find(:first).id).update_attributes(opts.merge(:created_on => Time.now, :submitter_user_id => 1))

      assert_count_decreases(Avatar) do
        post :destroy_returning, { :id => Avatar.find(:first).id }
      end
      assert_response :redirect
      u1.reload
      assert_equal cash + price_paid, u1.cash
    end
  end
end
