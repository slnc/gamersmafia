require File.dirname(__FILE__) + '/../test_helper'

class ReclutamientoControllerTest < ActionController::TestCase
  basic_test :index
  
  def test_nuevo_if_not_logged_in
    assert_raises(AccessDenied) { get :nuevo }
  end
  
  def test_nuevo_if_logged_in
    sym_login 1
    get :nuevo
    assert_response :success
  end
  
  def test_create_type_1
    sym_login 1
    assert_count_increases(RecruitmentAd) do
      post :anuncio_create, :reclutsearching => 'clan', :recruitment_ad => { :message => 'fulanitos del copon', :game_id => 1, :levels => ['low', 'med', 'high'], :clan_id => '1'}
    end
    @ra = RecruitmentAd.find(:first, :order => 'id DESC')
    assert_equal 'fulanitos del copon', @ra.message
    assert_nil @ra.clan_id
  end
  
  def test_create_type_2
    sym_login 1
    assert_count_increases(RecruitmentAd) do
      post :anuncio_create, :reclutsearching => 'users', :recruitment_ad => { :message => 'fulanitos del copon', :game_id => 1, :clan_id => 1}
    end
    @ra = RecruitmentAd.find(:first, :order => 'id DESC')
    assert_equal 'fulanitos del copon', @ra.message
  end
  
  def test_anuncio
    test_create_type_1
    get :anuncio, :id => @ra.id
    assert_response :success
  end
  
  def test_del_by_owner
    test_create_type_1
    post :anuncio_destroy, :id => @ra.id
    @ra.reload
    assert @ra.deleted?
  end
  
  def test_del_by_foreigner
    test_create_type_1
    sym_login 3
    assert_raises(AccessDenied) do
      post :anuncio_destroy, :id => @ra.id
    end
  end
  
  def test_del_by_capo
    test_create_type_1
    u2 = User.find(2)
    u2.give_admin_permission(:capo)
    sym_login 2
    post :anuncio_destroy, :id => @ra.id
    @ra.reload
    assert @ra.deleted?
  end
  
  def test_update
    test_create_type_1
    post :anuncio_update, :id => @ra.id, :recruitment_ad => { :game_id => 2 }
    @ra.reload
    assert_equal 2, @ra.game_id
    assert_redirected_to "/reclutamiento/anuncio/#{@ra.id}"
  end
  
  def test_buscar
    assert_count_increases(RecruitmentAd) do
      RecruitmentAd.create(:user_id => 1, :game_id => 1)
    end
    get :index, :search => 1, :game_id => 1, :type => 'searching_clan'
    assert_response :success
    assert @response.body.index("#{User.find(1).login} busca clan")
  end
end
