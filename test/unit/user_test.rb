require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end
  
  def test_faith_ok
    u = User.find(1)
    
    assert u.faith_points == 5
  end
  

  
  def test_is_editor
    u2 = User.find(2)
    assert u2.is_editor?
  end
  
  
  def test_should_send_email_to_add_user_to_hq
    prev = ActionMailer::Base.deliveries.size
    @p = User.find_by_login(:panzer)
    @p.is_hq = true
    @p.save
    assert_equal prev + 2, ActionMailer::Base.deliveries.size
  end
  
  def test_find_with_permissions
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
  
  def test_del_user_from_hq_should_work
    test_should_send_email_to_add_user_to_hq
    #prev = ActionMailer::Base.deliveries.size
    @p.is_hq = false
    assert @p.save
    #assert_equal prev + 1, ActionMailer::Base.deliveries.size
  end
  
  def test_create
    # TODO granuralize this
    params = {:login => 'dharana', :password => 'limitedconsistency', :email => 'dharana@dharana.net', :ipaddr => '127.0.0.1', :lastseen_on => Time.now}
    u = User.new(params)
    assert_equal true, u.save, u.errors.full_messages.to_yaml
    assert u.kind_of?(User)
    assert_equal 'dharana', u.login
    assert_equal Digest::MD5.hexdigest('limitedconsistency'), u.password
  end
  
  def test_find_by_login_should_behave_correctly
    u = User.find(1)
    assert_equal u.id, User.find_by_login(u.login).id
    assert_equal u.id, User.find_by_login(u.login.upcase).id
    assert_equal u.id, User.find_by_login(u.login.downcase).id
    assert_nil User.find_by_login('AAAAAAAAAAAAAAAAAAA')
  end
  
  def test_age_should_return_nil_if_no_birthday_set
    u = User.create({:login => 'moon', :email => 'moon@moon.moon'})
    assert_nil u.birthday
    assert_nil u.age
  end
  
  
  def test_flash_age
    u = User.create({:login => 'Flashky', :email => 'moon@moon.moon', :birthday => DateTime.new(1988, 3, 26)})
    assert_equal 20, u.age(DateTime.new(2009, 3, 25))
    assert_equal 21, u.age(DateTime.new(2009, 3, 26))
    assert_equal 21, u.age(DateTime.new(2009, 3, 27))
  end
  
  # GM-2531
  def test_flash_age_hoy
    u = User.create({:login => 'Flashky', :email => 'moon@moon.moon', :birthday => DateTime.new(1988, 3, 26)})
    years = DateTime.now.year - u.birthday.year
    assert([(years - 1), years].include?(u.age), u.age)
  end

  def test_check_age    
    u = User.find(1) 
    
    u.birthday = DateTime.new(1800, 3, 26)    
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

  
  def test_should_allow_youtube_videos_on_profile
    u = User.find(1)
    youtube_embed = '<object width="425" height="350"><param name="movie" value="http://www.youtube.com/v/2Iw1uEVaQpA"></param><param name="wmode" value="transparent"></param><embed src="http://www.youtube.com/v/2Iw1uEVaQpA" type="application/x-shockwave-flash" wmode="transparent" width="425" height="350"></embed></object>'
    u.description = youtube_embed
    assert_equal true, u.save
    u.reload
    assert_equal youtube_embed, u.description
  end
  
  def test_changing_last_commented_on_should_change_state_from_shadow
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
  
  def test_user_shouldnt_go_into_negative_remaining_ratings
    u1 = User.find(1)
    u1.cache_remaining_rating_slots = -1
    assert_equal true, u1.save
    assert_equal true, u1.remaining_rating_slots >= 0
    User.db_query("UPDATE users SET cache_remaining_rating_slots = -1 where id = 1")
    u1.reload
    assert_equal true, u1.remaining_rating_slots >= 0
  end
  
  def test_disable_all_email_notifications_should_work
    u1 = User.find(1)
    u1.notifications_global = true
    assert u1.save
    assert_count_increases(Message) do
      u1.disable_all_email_notifications
    end
    u1.reload
    assert !u1.notifications_global
  end
  
  def test_ligoteo
    u1 = User.find(1)
    u2 = User.find(2)
    assert u1.update_attributes(:sex => User::MALE)
    assert u2.update_attributes(:sex => User::FEMALE)
    u1.pref_interested_in = 'women'
    u1.pref_looking_for = ['quedar', 'amistad']
    
    u2.pref_interested_in = 'men women'
    u2.pref_looking_for = ['quedar', 'amistad']
    
    # hombre buscando mujeres interesadas en hombres
    ulw = User.ligoteo('women', User::MALE, 1)
    assert ulw.size > 0
    assert_equal 2, ulw[0].id
    
    # mujer buscando mujeres interesadas en mujeres
    ulw = User.ligoteo('women', User::FEMALE, 2)
    assert ulw.size == 0
    
    # hombres buscando hombres interesados en hombres
    ulw = User.ligoteo('men', User::MALE, 1)
    assert ulw.size == 0
    
    # mujeres buscando hombres interesados en mujeres
    ulw = User.ligoteo('men', User::FEMALE, 2) 
    assert ulw.size > 0
    assert_equal 1, ulw[0].id
  end
  
  def test_banning_user_should_remove_all_his_permissions
    u1 = User.find(1)
    ur1 = u1.users_roles.create(:role => 'Don', :role_data => '1')
    assert !ur1.new_record?
    u1.change_internal_state('banned')
    assert_equal 0, u1.users_roles.count
  end
  
  def test_avatar_change_not_allowed_if_custom_from_other
    u1 = User.find(1)
    av1 = Avatar.find(1)
    assert av1.update_attributes(:faction_id => nil, :user_id => 2)
    assert_raises(AccessDenied) do
      u1.change_avatar(av1.id)
    end
  end
  
  def test_avatar_change_not_allowed_if_clan_id_from_other
    u1 = User.find(1)
    av1 = Avatar.find(1)
    assert av1.update_attributes(:faction_id => nil, :clan_id => 2)
    assert_raises(AccessDenied) do
      u1.change_avatar(av1.id)
    end
  end
  
  def test_avatar_change_not_allowed_if_faction_from_other
    u1 = User.find(1)
    av1 = Avatar.find(1)
    assert av1.update_attributes(:faction_id => 2)
    assert_raises(AccessDenied) do
      u1.change_avatar(av1.id)
    end
  end
  
  def test_avatar_change_allowed_if_custom_from_self
    u1 = User.find(1)
    av1 = Avatar.find(1)
    assert av1.update_attributes(:faction_id => nil, :user_id => 1)
    assert u1.change_avatar(av1.id)
    assert_equal av1.id, u1.avatar_id
  end
  
  def test_avatar_change_allowed_if_faction_from_self
    u1 = User.find(1)
    Factions.user_joins_faction(u1, 1)
    av1 = Avatar.find(1)
    assert_not_nil u1.faction_id
    assert av1.update_attributes(:faction_id => u1.faction_id)
    assert u1.change_avatar(av1.id)
    assert_equal av1.id, u1.avatar_id
  end
  
  def test_avatar_change_allowed_if_clan_from_self
    u1 = User.find(1)
    av1 = Avatar.find(1)
    assert av1.update_attributes(:faction_id => nil, :clan_id => u1.clans_ids.first)
    assert u1.change_avatar(av1.id)
    assert_equal av1.id, u1.avatar_id
  end
  
end


