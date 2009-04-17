require 'test_helper'
require 'cuenta/mensajes_controller'

# Re-raise errors caught by the controller.
class Cuenta::MensajesController; def rescue_action(e) raise e end; end

class Cuenta::MensajesControllerTest < ActionController::TestCase

  
  def test_mensajes_should_work
    sym_login 1
    get :mensajes
    assert_response :success
  end
  
  def test_mensajes_enviados_should_work
    sym_login 1
    get :mensajes_enviados
    assert_response :success
  end
  
  def test_new
    sym_login 1
    get :new, :id => 2
    assert_response :success
  end
  
  def test_del_messages_should_work
    sym_login 1
    m = Message.find(1)
    assert !m.sender_deleted
    post :del_messages, { :messages => [1]}
    m.reload
    assert m.sender_deleted
    assert_response :redirect
  end
  
  def test_mensaje_should_work
    m1 = Message.find(1)
    sym_login m1.user_id_to
    get :mensaje, {:id => m1.id}
    assert_response :success
    assert_equal true, @response.body.include?(m1.title)
  end
  
  def test_create_message_should_work_if_user
    sym_login 1
    assert_count_increases(Message) do
      post :create_message, { :message=> {:message_type => Message::R_USER, :recipient_user_login => User.find(2).login, :title => "foo litio", :message => "soy litio teodorakis" }}
      assert_response :redirect
    end
  end
  
  def test_create_message_should_work_if_clan_not_given
    u1 = User.find(1)
    c1 = Clan.find(1)
    
    c1.admins<< User.find(3)
    u1.last_clan_id = 1
    u1.save
    c1.members<< User.find(2)
    
    sym_login 1
    msgs = Message.count
    
    post :create_message, { :message=> {:message_type => Message::R_CLAN, :title => "foo litio", :message => "soy litio teodorakis" }}
    assert_response :redirect
    assert_equal (msgs + c1.all_users_of_this_clan.size - 1), Message.count
    
    m_ids = Message.find(:all, :order => 'created_on desc', :limit => 2).collect{ |m| m.user_id_to }
    assert_equal true, m_ids.include?(2)
    assert_equal true, m_ids.include?(3)
  end
  
  def test_create_message_should_work_if_clan_given_and_different_than_last_clan_id
    u1 = User.find(1)
    c1 = Clan.find(1)
    
    c1.admins<< User.find(3)
    u1.last_clan_id = 2
    u1.save
    c1.members<< User.find(2)
    
    sym_login 1
    msgs = Message.count
    
    post :create_message, { :message=> {:message_type => Message::R_CLAN, :recipient_clan_id => 1, :title => "foo litio", :message => "soy litio teodorakis" }}
    assert_response :redirect
    assert_equal (msgs + c1.all_users_of_this_clan.size - 1), Message.count
    
    m_ids = Message.find(:all, :order => 'created_on desc', :limit => 2).collect{ |m| m.user_id_to }
    assert_equal true, m_ids.include?(2)
    assert_equal true, m_ids.include?(3)
  end
  
  def test_create_message_should_work_if_faction
    Factions::user_joins_faction(User.find(1), 1)
    Factions::user_joins_faction(User.find(2), 1)
    Factions::user_joins_faction(User.find(3), 1)
    Faction.find(1).update_boss(User.find(1))
    sym_login 1
    msgs = Message.count
    post :create_message, { :message=> {:message_type => Message::R_FACTION, :title => "foo litio", :message => "soy litio teodorakis" }}
    assert_response :redirect
    assert_equal (msgs + Faction.find(1).users.count - 1), Message.count
  end
  
  def test_create_message_should_work_if_faction_staff
    Factions::user_joins_faction(User.find(1), 1)
    f1 = Faction.find(1)
    f1.add_editor(User.find(2), ContentType.find_by_name('Column'))
    f1.add_editor(User.find(2), ContentType.find_by_name('News'))
    f1.add_moderator(User.find(3))
    f1.update_underboss(User.find(56))
    sym_login 56
    msgs = Message.count
    post :create_message, { :message=> {:message_type => Message::R_FACTION_STAFF, :title => "foo litio", :message => "soy litio teodorakis" }}
    assert_response :redirect
    assert_equal (msgs + 3), Message.count
  end
  
  def test_create_message_should_work_if_friends
    u1 = User.find(1)
    assert u1.friends.size > 0

    sym_login 1
    msgs = Message.count
    post :create_message, { :message=> {:message_type => Message::R_FRIENDS, :title => "foo litio", :message => "soy litio teodorakis" }}
    assert_response :redirect
    assert_equal true, u1.friends_count > 0
    assert_equal (msgs + u1.friends_count), Message.count
  end
  
  def test_sending_message_to_unexisting_user_should_say_what_happened
    sym_login 1
    post :create_message, { :message=> {:message_type => Message::R_USER, :recipient_user_login => "akjsdKQ!Kdk", :title => "foo litio", :message => "soy litio teodorakis" }}
    assert_equal true, flash[:error].to_s != ''
    assert_response :redirect
  end
  
  # TODO test del_messages
end
