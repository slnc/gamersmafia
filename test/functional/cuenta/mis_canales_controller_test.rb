require 'test_helper'
require 'cuenta/mis_canales_controller'

# Re-raise errors caught by the controller.
class Cuenta::MisCanalesController; def rescue_action(e) raise e end; end

class Cuenta::MisCanalesControllerTest < ActionController::TestCase

  
  def test_index_should_work
    sym_login 1
    get :index
    assert_response :success
    assert_template 'index'
  end
  
  def test_editar_should_work
    sym_login 1
    get :editar, { :id => 1 }
    assert_response :success
    assert_template 'editar'
  end
  
  def test_update_should_work
    sym_login 1
    channel1 = GmtvChannel.find(:first, :conditions => 'user_id = 1')
    assert_not_nil channel1
    prev_h = channel1.file
    post :update, { :id => 1, :gmtv_channel => { :file => fixture_file_upload('files/header.swf')} }
    assert_redirected_to '/cuenta/mis_canales/editar/1'
    channel1.reload
    assert_equal false, (channel1.file == prev_h)
  end
end
