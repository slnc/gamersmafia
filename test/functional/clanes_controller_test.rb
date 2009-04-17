require 'test_helper'
require 'clanes_controller'

# Re-raise errors caught by the controller.
class ClanesController; def rescue_action(e) raise e end; end

class ClanesControllerTest < ActionController::TestCase

  
  def test_index
    get :index
    assert_response :success
    assert_template 'clanes/index'
  end
  
  def test_index_should_work_on_platform
    @request.host = "#{FactionsPortal.find_by_code('wii').code}.#{App.domain}"
    get :index
    assert_response :success
    assert_template 'clanes/index'
  end
  
  def test_clan
    get :clan, :id => Clan.find(:first).id
    assert_response :success
    assert_template 'clanes/clan'
  end
  
  def test_clan_selector_list
    get :clan_selector_list
    assert_response :success
  end
  
  def test_buscar_should_redirect_if_no_search
    get :buscar
    assert_response :redirect
  end
  
  def test_buscar_should_work_if_searching
    get :buscar, { :s => 'indios'}
    assert_response :success
    assert @response.body.include?('Indios Mataharis')
  end
  
  def test_buscar_should_work_if_searching_deleted
    c = Clan.find_by_name('Indios Mataharis')
    assert c.update_attributes(:deleted => true)
    get :buscar, { :s => 'indios'}
    assert_response :success
    assert !@response.body.include?('Indios Mataharis')
  end
end
