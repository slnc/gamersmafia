require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  test "boss who changes to another faction should lose boss permission" do
    u = User.find(1)
    u.faction_id = 1
    assert u.save
    assert_equal 1, u.faction_id
    assert_count_increases(UsersRole) do
      u.users_roles.create(:role => 'Boss', :role_data => '1')
    end

    assert_count_decreases(UsersRole) do
      u.faction_id = 2
      assert u.save
      assert_nil u.users_roles.find_by_role('Boss')
    end
  end

  test "banning someone should remove all permissions" do
    u = User.find(1)
    u.users_roles.create(:role => 'Don', :role_data => '1')
    u.reload
    assert u.users_roles.count > 0
    assert u.update_attributes(:state => User::ST_BANNED)
    assert u.users_roles.count == 0
  end

  test "faith_ok" do
    u = User.find(1)
    assert u.faith_points == 5
  end

  test "website should do nothing if nothing" do
    u = User.find(1)
    assert u.update_attributes(:homepage => nil)
    assert u.update_attributes(:homepage => '')

    assert u.update_attributes(:homepage => 'http://serginho.com.ar')
    assert_equal 'http://serginho.com.ar', u.homepage
  end

  test "homepage should automatically add http if missing" do
    u = User.find(1)

    assert u.update_attributes(:homepage => 'serginho.com.ar')
    assert_equal 'http://serginho.com.ar', u.homepage
  end

  test "is_editor" do
    u2 = User.find(2)
    assert u2.is_editor?
  end


  test "check_is_hq should create message" do
    panzer = User.find_by_login('panzer')
    assert_difference('panzer.messages_received.count') do
      add_user_to_hq(panzer)
    end
  end

  def add_user_to_hq(user)
    assert user.update_attributes(:is_hq => true)
  end

  test "find_with_permissions" do
    u1 = User.find(1)
    assert u1.update_attributes(:admin_permissions => nil)
    assert u1.give_admin_permission(:capo)
    assert_equal '00000100000000', u1.admin_permissions
    u1.reload
    u1.reload
    capos = User.find_with_admin_permissions(:capo)
    assert_equal 1, capos.size
    assert_equal 1, capos[0].id
  end

  test "del_user_from_hq_should_work" do
    panzer = User.find_by_login('panzer')
    add_user_to_hq(panzer)
    assert panzer.update_attributes(:is_hq => false)
  end

  test "create" do
    # TODO granuralize this
    params = {:login => 'dharana', :password => 'limitedconsistency', :email => 'dharana@dharana.net', :ipaddr => '127.0.0.1', :lastseen_on => Time.now}
    u = User.new(params)
    assert_equal true, u.save, u.errors.full_messages.to_yaml
    assert u.kind_of?(User)
    assert_equal 'dharana', u.login
    assert_equal Digest::MD5.hexdigest('limitedconsistency'), u.password
  end

  test "find_by_login_should_behave_correctly" do
    u = User.find(1)
    assert_equal u.id, User.find_by_login(u.login).id
    assert_equal u.id, User.find_by_login(u.login.upcase).id
    assert_equal u.id, User.find_by_login(u.login.downcase).id
    assert_nil User.find_by_login('AAAAAAAAAAAAAAAAAAA')
  end

  test "age_should_return_nil_if_no_birthday_set" do
    u = User.create({:login => 'moon', :email => 'moon@moon.moon'})
    assert_nil u.birthday
    assert_nil u.age
  end


  test "flash_age" do
    u = User.create({:login => 'Flashky', :email => 'moon@moon.moon', :birthday => DateTime.new(1988, 3, 26)})
    assert_equal 20, u.age(DateTime.new(2009, 3, 25))
    assert_equal 21, u.age(DateTime.new(2009, 3, 26))
    assert_equal 21, u.age(DateTime.new(2009, 3, 27))
  end

  # GM-2531
  test "flash_age_hoy" do
    u = User.create({:login => 'Flashky', :email => 'moon@moon.moon', :birthday => DateTime.new(1988, 3, 26)})
    years = DateTime.now.year - u.birthday.year
    assert([(years - 1), years].include?(u.age), u.age)
  end

  test "check_age" do
    u = User.find(1)

    u.birthday = DateTime.new(1700, 3, 26)
    assert !u.save # No salvará bien, edad incorrecta (> 130 años)

    u.birthday = DateTime.now
    assert !u.save # No salvará bien, edad incorrecta (< 3 años)

    u.birthday = DateTime.new(DateTime.now.year - 3, DateTime.now.month, DateTime.now.day)
    assert u.save # Deberá salvar bien (3 >= edad <= 130)

    u.birthday = nil
    # Usuario que no tiene la edad fijada. Es una edad válida para el chequeo (pe: si el
    # usuario no ha fijado todavia su edad)
    assert_nil u.birthday # Comprobamos que efectivamente hay nil
    assert u.save         # Deberá salvar bien aun con birthday a nil
  end


  test "should_allow_youtube_videos_on_profile" do
    u = User.find(1)
    youtube_embed = '<object width="425" height="350"><param name="movie" value="http://www.youtube.com/v/2Iw1uEVaQpA"></param><param name="wmode" value="transparent"></param><embed src="http://www.youtube.com/v/2Iw1uEVaQpA" type="application/x-shockwave-flash" wmode="transparent" width="425" height="350"></embed></object>'
    u.description = youtube_embed
    assert_equal true, u.save
    u.reload
    assert_equal youtube_embed, u.description
  end

  test "changing_last_commented_on_should_change_state_from_shadow" do
    [User::ST_SHADOW, User::ST_ZOMBIE].each do |st|
      u1 = User.find(1)
      u1.state = st
      u1.lastcommented_on = nil
      assert_equal true, u1.save
      assert_equal st, u1.state
      u1.lastcommented_on = Time.now
      u1.save
      assert_equal User::ST_ACTIVE, u1.state
    end
  end

  test "user_shouldnt_go_into_negative_remaining_ratings" do
    u1 = User.find(1)
    u1.cache_remaining_rating_slots = -1
    assert_equal true, u1.save
    assert_equal true, u1.remaining_rating_slots >= 0
    User.db_query(
        "UPDATE users SET cache_remaining_rating_slots = -1 WHERE id = 1")
    u1.reload
    assert_equal true, u1.remaining_rating_slots >= 0
  end

  test "disable_all_email_notifications_should_work" do
    u1 = User.find(1)
    u1.notifications_global = true
    assert u1.save
    # Test deshabilitado temporalmente. Leer
    # User.disable_all_email_notifications para más info.
    assert_difference('Message.count', difference=0) do
      u1.disable_all_email_notifications
    end
    u1.reload
    assert !u1.notifications_global
  end

  test "banning_user_should_remove_all_his_permissions" do
    u1 = User.find(1)
    ur1 = u1.users_roles.create(:role => 'Don', :role_data => '1')
    assert !ur1.new_record?
    u1.change_internal_state('banned')
    assert_equal 0, u1.users_roles.count
  end

  test "avatar_change_not_allowed_if_custom_from_other" do
    u1 = User.find(1)
    av1 = Avatar.find(1)
    assert av1.update_attributes(:faction_id => nil, :user_id => 2)
    assert_raises(AccessDenied) do
      u1.change_avatar(av1.id)
    end
  end

  test "avatar_change_not_allowed_if_clan_id_from_other" do
    u1 = User.find(1)
    av1 = Avatar.find(1)
    assert av1.update_attributes(:faction_id => nil, :clan_id => 2)
    assert_raises(AccessDenied) do
      u1.change_avatar(av1.id)
    end
  end

  test "avatar_change_not_allowed_if_faction_from_other" do
    u1 = User.find(1)
    av1 = Avatar.find(1)
    assert av1.update_attributes(:faction_id => 2)
    assert_raises(AccessDenied) do
      u1.change_avatar(av1.id)
    end
  end

  test "avatar_change_allowed_if_custom_from_self" do
    u1 = User.find(1)
    av1 = Avatar.find(1)
    assert av1.update_attributes(:faction_id => nil, :user_id => 1)
    assert u1.change_avatar(av1.id)
    assert_equal av1.id, u1.avatar_id
  end

  test "avatar_change_allowed_if_faction_from_self" do
    u1 = User.find(1)
    Factions.user_joins_faction(u1, 1)
    av1 = Avatar.find(1)
    assert_not_nil u1.faction_id
    assert av1.update_attributes(:faction_id => u1.faction_id)
    assert u1.change_avatar(av1.id)
    assert_equal av1.id, u1.avatar_id
  end

  test "avatar_change_allowed_if_clan_from_self" do
    u1 = User.find(1)
    av1 = Avatar.find(1)
    assert av1.update_attributes(:faction_id => nil, :clan_id => u1.clans_ids.first)
    assert u1.change_avatar(av1.id)
    assert_equal av1.id, u1.avatar_id
  end

  def test_user_should_not_be_zombie_if_logged_in
    u1 = User.find(1)
    assert u1.update_attributes(:state => User::ST_ZOMBIE)
    u1.comments.each do |c|
      assert c.update_attributes(:created_on => 4.months.ago)
    end
    assert u1.update_attributes(:lastseen_on => Time.now)
    assert_equal User::ST_SHADOW, u1.state
  end

  test "comments_valorations_weights" do
    assert_equal 0.5, Comment.find(1).user.valorations_weights_on_self_comments
  end
end
