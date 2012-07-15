# -*- encoding : utf-8 -*-
require 'test_helper'

class Admin::CanalesControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :info, :del, :reset ]

  test "index_should_work" do
    sym_login 1
    get :index
    assert_response :success
  end

  test "info_should_work" do
    sym_login 1
    get :info, :id => 1
    assert_response :success
  end

  test "del_should_work" do
    sym_login 1
    assert_count_increases(SlogEntry) do
      assert_count_decreases(GmtvChannel) do
        post :del, :id => 1
        assert_response :redirect
      end
    end
  end

  test "reset_should_work_without_reason" do
    sym_login 1
    gmtv = GmtvChannel.find(1)
    gmtv.file = fixture_file_upload('files/buddha.jpg')
    assert_equal true, gmtv.save
    post :reset, :id => 1
    assert_response :redirect
    gmtv.reload
    assert_nil gmtv.file
  end

  test "reset_should_work_without_reason for non superadmin" do
    sym_login 56
    gmtv = GmtvChannel.find(1)
    gmtv.file = fixture_file_upload('files/buddha.jpg')
    assert_equal true, gmtv.save
    assert_count_increases(Message) do
      post :reset, :id => 1, :notify => '1', :reset_reason => 'foo'
      assert_response :redirect
    end
    gmtv.reload
    assert_nil gmtv.file
  end
end
