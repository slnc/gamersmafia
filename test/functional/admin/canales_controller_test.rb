require 'test_helper'

class Admin::CanalesControllerTest < ActionController::TestCase
  test_min_acl_level :superadmin, [ :index, :ino, :del, :reset ]
  
  def test_index_should_work
    sym_login 1
    get :index
    assert_response :success
  end
  
  def test_info_should_work
    sym_login 1
    get :info, :id => 1
    assert_response :success
  end
  
  def test_del_should_work
    sym_login 1
    assert_count_increases(SlogEntry) do
      assert_count_decreases(GmtvChannel) do
        post :del, :id => 1
        assert_response :redirect
      end
    end
  end
  
  def test_reset_should_work_without_reason
    sym_login 1
    gmtv = GmtvChannel.find(1)
    gmtv.file = fixture_file_upload('files/buddha.jpg')
    assert_equal true, gmtv.save
    post :reset, :id => 1
    assert_response :redirect
    gmtv.reload
    assert_nil gmtv.file
  end
  
  def test_reset_should_work_without_reason
    sym_login 56
    gmtv = GmtvChannel.find(1)
    gmtv.file = fixture_file_upload('files/buddha.jpg')
    assert_equal true, gmtv.save
    assert_count_increases(Message) do 
      post :reset, :id => 1, :notify => 1, :reset_reason => 'foo'
      assert_response :redirect
    end      
    gmtv.reload
    assert_nil gmtv.file
  end
end
