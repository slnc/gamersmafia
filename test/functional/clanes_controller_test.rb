require 'test_helper'

class ClanesControllerTest < ActionController::TestCase
  
  test "index" do
    get :index
    assert_response :success
    assert_template 'clanes/index'
  end
  
  test "index_should_work_on_platform" do
    @request.host = "#{FactionsPortal.find_by_code('wii').code}.#{App.domain}"
    get :index
    assert_response :success
    assert_template 'clanes/index'
  end
  
  test "clan" do
    get :clan, :id => Clan.find(:first).id
    assert_response :success
    assert_template 'clanes/clan'
  end
  
  test "competicion" do
    get :competicion, :id => Clan.find(:first).id
    assert_response :success
    assert_template 'clanes/competicion'
  end
  
  test "clan_selector_list" do
    get :clan_selector_list
    assert_response :success
  end
  
  test "buscar_should_redirect_if_no_search" do
    get :buscar
    assert_response :redirect
  end
  
  test "buscar_should_work_if_searching" do
    get :buscar, { :s => 'indios'}
    assert_response :success
    assert @response.body.include?('Indios Mataharis')
  end
  
  test "buscar_should_work_if_searching_deleted" do
    c = Clan.find_by_name('Indios Mataharis')
    assert c.update_attributes(:deleted => true)
    get :buscar, { :s => 'indios'}
    assert_response :success
    assert !@response.body.include?('Indios Mataharis')
  end
end
