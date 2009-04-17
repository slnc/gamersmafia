require 'test_helper'

class Cuenta::Clanes::SponsorsControllerTest < ActionController::TestCase
  
  def setup
    @controller = Cuenta::Clanes::SponsorsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @u1 = User.find(1)
    @c = Clan.find(1)
    @u1.last_clan_id = @c.id
    @u1.save
  end
  
  
  test "index" do
    sym_login 1
    assert @c.user_is_clanleader(@u1.id)
    get :index
    assert_response :success
    assert_template 'list'
  end
  
  test "new" do
    sym_login 1
    get :new
    
    assert_response :success
    assert_template 'new'
  end
  
  test "create" do
    sym_login 1
    assert_count_increases(ClansSponsor) do 
      post :create, :clans_sponsor => {:name => 'foo', :url => 'http://www.foo.com/', :image => fixture_file_upload('files/buddha.jpg', 'file/jpeg')}
      assert_response :redirect  
    end
    @cs = ClansSponsor.find(:first, :order => 'id desc')
  end
  
  test "edit" do
    test_create
    get :edit, :id => @cs.id
    assert_response :success
    assert_template 'edit'
  end
  
  test "update" do
    test_create
    assert_not_equal 'foo2', @cs.name
    post :update, :id => @cs.id, :clans_sponsor => {:name => 'foo2', :url => 'http://www.foo2.com/', :image => fixture_file_upload('files/buddha.jpg', 'file/jpeg')}
    assert_response :redirect
    assert_redirected_to :action => 'edit'
    @cs.reload
    assert_equal 'foo2', @cs.name
  end
  
  test "destroy" do
    test_create
    assert_count_decreases(ClansSponsor) do
      post :destroy, :id => @cs.id
      assert_response :redirect
      assert_redirected_to :action => 'list'
    end
    
    assert_raise(ActiveRecord::RecordNotFound) {
      ClansSponsor.find(@cs.id)
    }
  end
  
end
