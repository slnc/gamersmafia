# -*- encoding : utf-8 -*-
require 'test_helper'

class Cuenta::MensajesControllerTest < ActionController::TestCase
  test "mensajes_should_work" do
    sym_login 1
    get :mensajes
    assert_response :success
  end

  test "mensajes_enviados_should_work" do
    sym_login 1
    get :mensajes_enviados
    assert_response :success
  end

  test "new" do
    sym_login 1
    get :new, :id => 2
    assert_response :success
  end

  test "del_messages_should_work" do
    sym_login 1
    m = Message.find(1)
    assert !m.sender_deleted
    post :del_messages, { :messages => [1]}
    m.reload
    assert m.sender_deleted
    assert_response :redirect
  end

  test "mensaje should work" do
    m1 = Message.find(1)
    sym_login m1.user_id_to
    get :mensaje, {:id => m1.id}
    assert_response :success
    assert @response.body.include?(m1.title)
  end

  test "create_message should work if all ok" do
    create_message
  end

  test "should err on empty title" do
    sym_login 1
    assert_difference('Message.count', 0) do
      post :create_message, {:message => new_message_params(:title => "")}
      assert_response :success
    end
    assert @response.body.include?(Message::CANNOT_BE_EMPTY)
  end

  test "create_message_should_not_burp_if_nonexisting_user" do
    sym_login 1
    post :create_message, {
        :message=> new_message_params(:recipient_user_login => '()A>C!')}
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test "create_message_should_not_burp_if_replying_to_nonexistant_message" do
    sym_login 1
    assert_difference("Message.count") do
      post :create_message, { :message=> new_message_params(:in_reply_to => -1)}
      assert_response :redirect
      assert_nil flash[:error]
    end
  end

  test "create_message_should_work_if_clan_not_given" do
    u1 = User.find(1)
    c1 = Clan.find(1)

    c1.admins<< User.find(3)
    u1.last_clan_id = 1
    u1.save
    c1.members<< User.find(2)

    sym_login 1
    assert_difference("Message.count",
                      c1.all_users_of_this_clan.size - 1) do
      post :create_message, {
          :message=> new_message_params(:message_type => Message::R_CLAN)}
      assert_response :redirect
    end

    m_ids = Message.find(:all,
                         :order => 'created_on desc',
                         :limit => 2).collect{ |m| m.user_id_to }
    assert m_ids.include?(2)
    assert m_ids.include?(3)
  end

  test "create_message should work if clan and different than last clan" do
    u1 = User.find(1)
    c1 = Clan.find(1)

    c1.admins<< User.find(3)
    u1.last_clan_id = 2
    u1.save
    c1.members<< User.find(2)

    sym_login 1
    msgs = Message.count

    post :create_message, {
        :message=> new_message_params(:message_type => Message::R_CLAN,
                                      :recipient_clan_id => 1)}
    assert_response :redirect
    assert_equal (msgs + c1.all_users_of_this_clan.size - 1), Message.count

    m_ids = Message.find(:all,
                         :order => 'created_on desc',
                         :limit => 2).collect{ |m| m.user_id_to }
    assert_equal true, m_ids.include?(2)
    assert_equal true, m_ids.include?(3)
  end

  test "create_message_should_work_if_faction" do
    Factions::user_joins_faction(User.find(1), 1)
    Factions::user_joins_faction(User.find(2), 1)
    Factions::user_joins_faction(User.find(3), 1)
    Faction.find(1).update_boss(User.find(1))
    sym_login 1
    msgs = Message.count
    post :create_message, {
        :message=> new_message_params(:message_type => Message::R_FACTION)}
    assert_response :redirect
    assert_equal (msgs + Faction.find(1).users.count - 1), Message.count
  end

  test "create_message_should_work_if_faction_staff" do
    Factions::user_joins_faction(User.find(1), 1)
    f1 = Faction.find(1)
    f1.add_editor(User.find(2), ContentType.find_by_name('Column'))
    f1.add_editor(User.find(2), ContentType.find_by_name('News'))
    f1.add_moderator(User.find(3))
    u56 = User.find(56)
    f1.update_underboss(u56)
    assert f1.is_underboss?(u56)
    assert_equal 1, u56.faction_id
    sym_login 56
    msgs = Message.count
    post :create_message, {
        :message=> new_message_params(
            :message_type => Message::R_FACTION_STAFF)}
    assert_response :redirect
    assert_equal (msgs + 3), Message.count
  end

  test "create_message_should_work_if_friends" do
    u1 = User.find(1)
    assert u1.friends.size > 0

    sym_login 1
    msgs = Message.count
    post :create_message, {
        :message=> new_message_params(:message_type => Message::R_FRIENDS)}
    assert_response :redirect
    assert_equal true, u1.friends_count > 0
    assert_equal (msgs + u1.friends_count), Message.count
  end

  test "sending_message_to_unexisting_user_should_say_what_happened" do
    sym_login 1
    post :create_message, {
        :message=> new_message_params(:recipient_user_login => "akjsdKQ!Kdk")}
    assert_equal true, flash[:error].to_s != ''
    assert_response :redirect
  end

  test "sender reading a sent message shouldn't mark it as recipient read" do
    create_message
    m = Message.last
    get :mensaje, :id => m.id
    m.reload
    assert_response :success
    assert !m.is_read?
    sym_login 2
    get :mensaje, :id => m.id
    assert_response :success
    m.reload
    assert m.is_read?
  end

  protected
  def create_message
    sym_login 1
    # Creates a message through the SUT
    assert_count_increases(Message) do
      post :create_message, { :message=> self.new_message_params}
      assert_response :redirect
    end
  end

  # Returns all necessary params for a new message
  def new_message_params(opts={})
    {:message_type => Message::R_USER,
     :recipient_user_login => User.find(2).login,
     :title => "foo litio",
     :message => "soy litio teodorakis" }.update(opts)
  end
end
