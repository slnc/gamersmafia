require 'test_helper'

class Cuenta::Clanes::GeneralControllerTest < ActionController::TestCase  
  def test_should_not_create_invalid_clan
    sym_login 1
    c = Clan.count
    post :create, { :newclan => { :name => 'fooooooooooooooooooooooooooooooooooooooo', :tag => 'baaaaaaaaaaaaaaaaaaaaar'}}
    assert_response :success
    assert_template 'cuenta/clanes/general/new'
    assert_equal c, Clan.count
    assert_nil @clan
    assert_not_nil flash[:error]
  end
  
  def test_index_should_work
    sym_login 1
    get :index
    assert_response :success
  end
  
  def test_menu_should_work
    sym_login 1
    get :menu
    assert_response :success
  end
  
  def test_create_should_work
    sym_login 1
    assert_count_increases(Clan) do
      post :create, { :newclan => { :name => "hola", :tag => 'tag', :logo => fixture_file_upload('/files/buddha.jpg', 'image/jpeg')}}
      assert_response :redirect
    end
    @c = Clan.find(:first, :order => 'id desc')
    assert_equal 'hola', @c.name
    assert_equal 'tag', @c.tag
    assert @c.logo.include?('buddha.jpg')
    @u1 = User.find(1)
    assert @c.user_is_clanleader(@u1.id)
    assert_equal @c.id, @u1.last_clan_id 
  end
  
  def test_borrar_should_work_if_last_clanleader
    test_create_should_work
    assert !@c.deleted
    post :borrar, {:clan_id => @c.id}
    assert_redirected_to '/cuenta/clanes'
    assert_not_nil flash[:notice]
    @c.reload
    assert @c.deleted
  end
  
  def test_borrar_shouldnt_work_if_more_than_1_clanleaders
    test_create_should_work
    @c.admins<< User.find(2)
    assert_raises(AccessDenied) { post :borrar, {:clan_id => @c.id} }
  end
  
  def test_abandonar_should_work_if_not_last_member
    test_create_should_work
    @c.admins<< User.find(2)
    get :abandonar, {:clan_id => @c.id}
    assert_response :redirect
  end
  
  def test_abandonar_shouldnt_work_if_last_member
    test_create_should_work
    c = @c.all_users_of_this_clan.size
    assert_equal 1, c
    get :abandonar, {:clan_id => @c.id}
    @c.reload
    assert_response :redirect
    assert_not_nil flash[:error]
    assert_equal c, @c.all_users_of_this_clan.size
  end
  
  def test_update_should_work
    test_create_should_work
    assert_equal @c.id, @u1.last_clan_id
    post :update, { :clan => { :irc_channel => '#los_manolitos', :name => 'namae', :tag => 'taggae', :logo => fixture_file_upload('/files/buddha.jpg', 'image/jpeg'), :competition_roster => fixture_file_upload('/files/buddha.jpg', 'image/jpeg'), :irc_server => 'irc.quakenet.org', :website_external => 'http://www.fulanitos.com'}}
    assert_nil flash[:error]
    assert_response :redirect 
    @c.reload
    assert_equal 'los_manolitos', @c.irc_channel
  end
  
  def test_add_member_to_group_should_work
    test_create_should_work
    @cg = Clan.find(@u1.last_clan_id).clans_groups.find(:first)
    assert !@cg.has_user(2)
    post :add_member_to_group, { :login => User.find(2).login, :clans_group_id => @cg.id }
    assert_response :redirect
    @cg.reload
    assert @cg.has_user(2)
  end
  
  def test_remove_member_from_group_should_work
    test_add_member_to_group_should_work
    post :remove_member_from_group, { :user_id => 2, :clans_group_id => @cg.id }
    assert_response :redirect
    @cg.reload
    assert !@cg.has_user(2)
  end
  
  def test_configuracion_should_work
    test_create_should_work
    get :configuracion
    assert_response :success
  end
  
  def test_miembros_should_work
    test_create_should_work
    get :miembros
    assert_response :success
  end
  
  def test_amigos_should_work
    test_create_should_work
    get :amigos
    assert_response :success
  end
  
  def test_add_friend_should_work_if_giving_id
    test_create_should_work
    c_friends = @c.friends.size
    post :add_friend, { :id => 1 }
    assert_response :redirect
    @c.reload
    assert_equal c_friends + 1, @c.friends.size
  end
  
  def test_add_friend_should_work_if_giving_name
    test_create_should_work
    c_friends = @c.friends.size
    post :add_friend, { :name => Clan.find(1).name }
    assert_response :redirect
    @c.reload
    assert_equal c_friends + 1, @c.friends.size
  end
  
  def test_del_friends_should_work
    test_add_friend_should_work_if_giving_id
    c_friends = @c.friends.size
    post :del_friends, { :clans => [1] }
    assert_response :redirect
    @c.reload
    assert_equal c_friends - 1, @c.friends.size
  end
  
  def test_banco_should_work
    test_create_should_work
    get :banco
    assert_response :success
  end
  
  def test_switch_active_clan_should_work_if_switching_to_nil
    test_create_should_work
    get :switch_active_clan, { :id => ''}
    assert_response :redirect
    @u1.reload
    assert_nil @u1.last_clan_id
  end
  
  def test_switch_active_clan_should_work_if_switching_to_clan
    test_create_should_work
    assert_not_equal @u1.last_clan_id, 1
    get :switch_active_clan, { :id => 1}
    assert_response :redirect
    @u1.reload
    assert_equal @u1.last_clan_id, 1
  end
  
  def test_activate_website_should_work_if_product
    test_create_should_work
    assert_count_increases(SoldProduct) do
      @u1.sold_products.create({:price_paid => 1.0, :product_id => Product.find_by_cls('SoldClanWebsite').id})
    end
    assert_count_increases(ClansPortal) do
      get :activate_website
      assert_response :redirect
    end
    @clan = Clan.find(@u1.last_clan_id)
    assert_equal true, @clan.website_activated
  end
end