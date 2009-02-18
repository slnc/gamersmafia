require File.dirname(__FILE__) + '/../test_helper'

class FaccionControllerTest < ActionController::TestCase
  
  def test_index
    @request.host = "#{FactionsPortal.find(:first).code}.#{App.domain}"
    get :index
    assert_response :success
  end
  
  def test_miembros
    @request.host = "#{FactionsPortal.find(:first).code}.#{App.domain}"
    get :miembros
    assert_response :success
  end
  
  def test_clanes
    @request.host = "#{FactionsPortal.find(:first).code}.#{App.domain}"
    get :clanes
    assert_response :success
  end
  
  def test_staff
    @request.host = "#{FactionsPortal.find(:first).code}.#{App.domain}"
    get :staff
    assert_response :success
  end
end
