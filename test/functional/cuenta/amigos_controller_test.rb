require File.dirname(__FILE__) + '/../../test_helper'

class Cuenta::AmigosControllerTest < ActionController::TestCase
  def test_should_be_able_to_start_friendship
    assert_raises(AccessDenied) { get :index }
    sym_login 5
    @u4 = User.find(4)
    assert_count_increases(Friendship) { post :iniciar_amistad, { :login => @u4.login } }
    assert_redirected_to "/miembros/#{@u4.login}"
  end
  
  def test_should_be_able_to_cancel_friendship
    test_should_be_able_to_start_friendship
    assert_count_decreases(Friendship) { post :cancelar_amistad, { :login => @u4.login } }
    assert_redirected_to "/cuenta/amigos"
  end
  
  def test_should_send_email_invitations
    sym_login 1
    hsh = {}
    inicial = ActionMailer::Base.deliveries.size
     (1..5).each do |i|
      hsh["email_invitation_eml#{i}".to_sym] = "eml#{i}@laflecha.net"
      hsh["email_invitation_msg#{i}".to_sym] = "Feolin #{i}"
    end
    post :invitar_email, hsh
    assert_response :redirect
    assert_equal inicial + 5, ActionMailer::Base.deliveries.size
  end
  
  def test_should_be_able_to_cancel_email_invitations
    sym_login 1
    
    assert_count_increases(Friendship) do
      post :invitar_email, { :email_invitation_eml1 => 'foochicki@bar.com', :email_invitation_msg => 'baz'}
      assert_response :redirect
    end
    
    assert_count_decreases(Friendship) do
      post :cancelar_amistad, { :eid => Friendship.find(:first, :order => 'id desc').external_invitation_key }
      assert_response :redirect
    end
  end
  
  def test_cancel_external_invitation_should_work_if_not_authed
    f = Friendship.new({:sender_user_id => 1, :receiver_email => 'dharana@dharana.net', :invitation_text => 'guapooo'})
    assert_equal true, f.save
    assert_count_decreases(Friendship) do
      post :cancelar_amistad, { :eid => f.external_invitation_key }
      assert_response :redirect
    end
  end
  
  def test_should_be_able_to_get_the_accept_email_invitation_screen
    f5 = Friendship.find(5)
    get :aceptar_amistad, { :eik => f5.external_invitation_key }
    assert_response :success
    assert_nil(session[:user])
    # TODO test that the original email's user part is shown
    #    assert_equal true, @response.body.index(f5.receiver_email...?)
  end
  
  def test_should_be_able_to_create_new_account_when_accepting_email_invitation_and_stablish_friendship
    f5 = Friendship.find(5)
    m_initial = ActionMailer::Base.deliveries.size
    assert_count_increases(User) do
      post :create_and_accept_friendship, { :eik => f5.external_invitation_key, :u => { :login => 'nuevoamigo', :password => 'bleh', :password_confirm => 'bleh'} }
      assert_redirected_to "/cuenta", @response.body
    end
    
    
    ul = User.find_by_login('nuevoamigo')
    assert_not_nil ul
    f5.reload
    assert_equal ul.id, f5.receiver_user_id
    assert_equal true, f5.accepted_on.to_i > Time.now.to_i  - 5
    # assert_equal m_initial + 1, ActionMailer::Base.deliveries.size # send notice to sender that his friend signed up
  end
  
  def test_should_add_local_user_if_trying_to_add_email_of_already_registered_user
    hsh = {}
    hsh["email_invitation_eml1".to_sym] = User.find(2).email
    hsh["email_invitation_msg1".to_sym] = "Feolin"
    Friendship.find_between(User.find(1), User.find(2)).destroy
    sym_login 1
    post :invitar_email, hsh
    assert_response :redirect
    f = Friendship.find(:first, :order => 'id desc')
    assert_equal 2, f.receiver_user_id
    assert_nil f.receiver_email
  end
  
  def test_olvidadme_should_work_if_valid_eik_key
    @f5 = Friendship.find(5)
    m_initial = ActionMailer::Base.deliveries.size
    assert_count_increases(SilencedEmail) do
      post :olvidadme, { :eik => @f5.external_invitation_key }
      assert_redirected_to "/", @response.body
    end
    se = SilencedEmail.find(:first, :order => 'id desc')
    assert_not_nil se
    assert_equal @f5.receiver_email, se.email
  end
  
  def test_send_invitation_to_external_user_shouldnt_send_invitation_to_silenced_email
    test_olvidadme_should_work_if_valid_eik_key
    inicial = ActionMailer::Base.deliveries.size
    hsh = {}
    hsh["email_invitation_eml1".to_sym] = @f5.receiver_email
    hsh["email_invitation_msg1".to_sym] = "Feolin"
    
    sym_login 1
    post :invitar_email, hsh
    assert_response :redirect
    assert_equal inicial, ActionMailer::Base.deliveries.size
  end
end
