require 'test_helper'
require 'notification'
load RAILS_ROOT + '/Rakefile'

class NotificationTest < ActiveSupport::TestCase
  include Rake
  
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8" 
  
  include ActionMailer::Quoting
  
  
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    
    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end
  
  test "support_db_oos" do
    assert_count_increases(ActionMailer::Base.deliveries) do
      Notification.deliver_support_db_oos(:prod => 1.minute.ago, :support => 5.minutes.ago)
    end
  end
  
  test "yourebanned" do
    assert_count_increases(ActionMailer::Base.deliveries) do
      Notification.deliver_yourebanned(User.find(1), { :reason => "Feo" })
    end
  end
  
  test "weekly_avg_page_render_time" do
    sample_output = {'avg' => '2.1', 'stddev' => '5.1', 'controller' => 'bar', 'action' => 'foo', 'count' => '5'}
    Notification.deliver_weekly_avg_page_render_time({ :top_avg_time => [sample_output], :top_count => [sample_output] })
  end
  
  
  test "new_factions_banned_user" do
    sender = User.find(1)
    recipient = User.find(2)
    deliveries = ActionMailer::Base.deliveries.size
    fb = FactionsBannedUser.new({:faction_id => 1, :user_id => 2, :reason => 'más feo que el hambre', :banner_user_id => 1})
    #    assert_equal false, fb.new_record?
    Notification.deliver_new_factions_banned_user('webmaster@gamersmafia.com', { :sender => fb.banner_user, :factions_ban => fb })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "faction_summary" do
    sender = User.find(1)
    recipient = User.find(2)
    deliveries = ActionMailer::Base.deliveries.size
    
    Notification.deliver_faction_summary(recipient, { :faction => Faction.find(1) })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "invited_participant" do
    recipient = User.find(1)
    deliveries = ActionMailer::Base.deliveries.size
    Notification.deliver_invited_participant(recipient, { :competition => Competition.find(:first) })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "del_from_hq" do
    sender = User.find(1)
    recipient = User.find(2)
    deliveries = ActionMailer::Base.deliveries.size
    
    Notification.deliver_del_from_hq(recipient)
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "add_to_hq" do
    sender = User.find(1)
    recipient = User.find(2)
    deliveries = ActionMailer::Base.deliveries.size
    
    Notification.deliver_add_to_hq(sender, :new_member => recipient)
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "newmessage" do
    sender = User.find(1)
    recipient = User.find(2)
    deliveries = ActionMailer::Base.deliveries.size
    nm = Message.new({:user_id_from => sender.id, :user_id_to => recipient.id, :title => 'Mensaje de prueba', :message => 'texto del mensaje de prueba', :created_on => Time.now})
    
    Notification.deliver_newmessage(recipient, { :sender => sender, :message => nm })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "should_log_emails_sent" do
    assert_count_increases(SentEmail) do
      test_newmessage
    end
  end
  
  test "newprofilesignature" do
    sender = User.find(1)
    recipient = User.find(2)
    deliveries = ActionMailer::Base.deliveries.size
    Notification.deliver_newprofilesignature(recipient, { :signer => sender })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "competition_started" do
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type <> \'Ladder\'')
    u = User.find(1)
    u2 = User.find(2)
    assert_not_nil c
    assert_equal 0, c.admins.size
    c.add_admin(u)
    assert_equal 1, c.admins.size
    #assert_equal true, c.competitions_participants.create({:participant_id => u.id, :name => u.login, :competitions_participants_type_id => c.competitions_participants_type_id, :roster => u.show_avatar})
    deliveries = ActionMailer::Base.deliveries.size
    Notification.deliver_competition_started(u2, { :sender => c.admins[0], :competition => c})
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "welcome" do
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    Notification.deliver_welcome(u1)
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "forgot" do
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    Notification.deliver_forgot(u1)
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "signup" do
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    Notification.deliver_signup(u1)
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "emailchange" do
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    Notification.deliver_emailchange(u1)
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "ad_report" do
    deliveries = ActionMailer::Base.deliveries.size
    Notification.deliver_ad_report(Advertiser.find(:first), {:tstart => 1.week.ago, :tend => Time.now})
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "newregistration" do
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    u2 = User.find(2)
    Notification.deliver_newregistration(u1, { :refered => u2 })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "resurrection" do
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    u2 = User.find(2)
    Notification.deliver_resurrection(u1, { :resurrected => u2 })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  
  test "reto_aceptado" do
    # TODO brittle test
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
    assert_not_nil c
    p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
    Notification.deliver_reto_aceptado(u, { :participant => p })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "reto_recibido" do
    # TODO brittle test
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
    assert_not_nil c
    p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
    Notification.deliver_reto_recibido(u, { :participant => p })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "reto_pendiente_1w" do
    # TODO brittle test
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
    assert_not_nil c
    p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
    Notification.deliver_reto_pendiente_1w(u, { :participant => p })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "reto_pendiente_2w" do
    # TODO brittle test
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
    assert_not_nil c
    p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
    Notification.deliver_reto_pendiente_2w(u, { :participant => p })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "reto_cancelado_sin_respuesta" do
    # TODO brittle test
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
    assert_not_nil c
    p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
    Notification.deliver_reto_cancelado_sin_respuesta(u, { :participant => p })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "rechallenge" do
    test_reto_recibido
    assert_count_increases(ActionMailer::Base.deliveries) do
      u = User.find(1)
      c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
      p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
      Notification.deliver_rechallenge(u, { :participant => p })
    end
  end
  
  test "reto_rechazado" do
    # TODO brittle test
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
    assert_not_nil c
    p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
    Notification.deliver_reto_rechazado(u, { :participant => p })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "trackerupdate" do
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Content.find(:first)
    assert_not_nil c
    Notification.deliver_trackerupdate(u, { :content => c.real_content })
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end
  
  test "unconfirmed_1w" do
    assert_count_increases(ActionMailer::Base.deliveries) do
      u1 = User.find(1)
      Notification.deliver_unconfirmed_1w(u1)
    end
  end
  
  test "unconfirmed_2w" do
    assert_count_increases(ActionMailer::Base.deliveries) do
      Notification.deliver_unconfirmed_1w(User.find(1))
    end
  end
  
  test "newcontactar" do
    assert_count_increases(ActionMailer::Base.deliveries) do
      Notification.deliver_newcontactar(:subject => 'hola', :message => 'que tal', :email => 'fulanito de tal')
    end
  end
  
  test "new_friendship_request" do
    recipient = User.find(2)
    u1 = User.find(1)
    deliveries = ActionMailer::Base.deliveries.size
    Notification.deliver_new_friendship_request(recipient, {:from => "#{u1.login} <#{u1.email}>", :invitation_key => '4d186321c1a7f0f354b297e8914ab240', :sender => u1})
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
    assert_equal true, ActionMailer::Base.deliveries.last.to_s.include?("From: #{u1.login} <#{u1.email}>"), ActionMailer::Base.deliveries.last
  end
  
  test "new_friendship_request_external" do
    recipient = User.find(2)
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    Notification.deliver_new_friendship_request_external(recipient, {:from => "#{u1.login} <#{u1.email}>", :invitation_key => '4d186321c1a7f0f354b297e8914ab240', :sender => u1})
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
    #assert_equal true, ActionMailer::Base.deliveries.last.to_s.include?("From: #{u1.login} <#{u1.email}>"), ActionMailer::Base.deliveries.last 
  end
  
  test "new_friendship_accepted" do
    sender = User.find(1)    
    assert_count_increases(ActionMailer::Base.deliveries) do
      Notification.deliver_new_friendship_accepted(sender, { :receiver => User.find(2)})
    end
  end
  
  private
  def read_fixture(action)
    IO.readlines("#{FIXTURES_PATH}/notification/#{action}")
  end
  
  def encode(subject)
    quoted_printable(subject, CHARSET)
  end
end
