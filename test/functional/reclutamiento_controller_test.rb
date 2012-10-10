# -*- encoding : utf-8 -*-
require 'test_helper'
require 'test_functional_content_helper'

class ReclutamientoControllerTest < ActionController::TestCase
  basic_test :index

  test "create_type_1" do
    sym_login 1
    assert_count_increases(RecruitmentAd) do
      post :create, {
          :reclutsearching => 'clan',
          :recruitment_ad => {
              :title => 'buscamos miembros',
              :main => 'fulanitos del copon',
              :game_id => 1,
              :levels => ['low', 'med', 'high'],
              :clan_id => '1',
          },
      }
    end
    @ra = RecruitmentAd.find(:first, :order => 'id DESC')
    assert_equal 'fulanitos del copon', @ra.main
    assert_nil @ra.clan_id
  end

  test "create_type_2" do
    sym_login 1
    assert_count_increases(RecruitmentAd) do
      post :create, {
          :reclutsearching => 'users',
          :recruitment_ad => {
              :title => 'buscamos miembros',
              :main => 'fulanitos del copon',
              :game_id => 1,
              :clan_id => 1,
          },
      }
    end
    @ra = RecruitmentAd.find(:first, :order => 'id DESC')
    assert_equal 'fulanitos del copon', @ra.main
  end

  test "del_by_owner" do
    test_create_type_1
    post :destroy, :id => @ra.id
    @ra.reload
    assert_equal Cms::DELETED, @ra.state
  end

  test "del_by_foreigner" do
    test_create_type_1
    sym_login 2
    assert_raises(AccessDenied) do
      post :destroy, :id => @ra.id
    end
  end

  test "del_by_capo" do
    test_create_type_1
    give_skill(2, "DeleteContents")
    u2 = User.find(2)
    sym_login 2
    post :destroy, :id => @ra.id
    @ra.reload
    assert_equal Cms::DELETED, @ra.state
  end

  test "update" do
    test_create_type_1
    sym_login 1
    post :update, :id => @ra.id, :recruitment_ad => { :game_id => 2 }
    @ra.reload
    assert_equal 2, @ra.game_id
    assert_redirected_to Routing.gmurl(@ra)
  end

  test "buscar" do
    ra = RecruitmentAd.new(:user_id => 1, :game_id => 1, :title => 'booooh')
    assert_count_increases(RecruitmentAd) do
      assert ra.save
    end

    Content.publish_content_directly(ra, User.find(1))
    get :index, :search => 1, :game_id => 1, :type => 'searching_clan'
    assert_response :success
    assert @response.body.index("#{User.find(1).login}"), @response.body
  end
end
