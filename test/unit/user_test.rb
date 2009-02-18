require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
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
  
  # this will break on 31 dec, 1 jan
  def test_age_ok_if_birthday_is_earlier_this_year
    #u = User.find(:first)
    #now_d = DateTime.now
    #u.birthday = DateTime.new(now_d.year, self.birthday.month, self.birthday.day
  end
  
  def test_age_ok_if_moon
    d = DateTime.new(1978, 2, 4)
    today = DateTime.now
    u = User.create({:login => 'moon', :email => 'moon@moon.moon', :birthday => d})
    assert_not_nil u
    assert_equal d, u.birthday
    if today.month > u.birthday.month or (today.month == u.birthday.month and today.day == u.birthday.day) then # ya ha sido su cumpleaños
      assert_equal today.year - u.birthday.year, u.age
    else # ya ha sido su cumpleaños o es hoy
      assert_equal today.year - u.birthday.year - 1, u.age
    end
  end
  
  def test_age_ok_if_birthday_is_today
    today = DateTime.now
    u = User.create({:login => 'moon', :email => 'moon@moon.moon', :birthday => 20.years.ago})
    assert_not_nil u
    assert_equal 20, u.age
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
end
