# -*- encoding : utf-8 -*-
require 'test_helper'

class NotificationEmailTest < ActionMailer::TestCase
  test "yourebanned" do
    assert_difference("ActionMailer::Base.deliveries.size") do
      NotificationEmail.yourebanned(User.find(1), { :reason => "Feo" }).deliver
    end
  end

  test "weekly_avg_page_render_time" do
    sample_output = {
        'avg' => '2.1',
        'stddev' => '5.1',
        'controller' => 'bar',
        'action' => 'foo',
        'count' => '5'
    }

    assert_difference("ActionMailer::Base.deliveries.size") do
      NotificationEmail.weekly_avg_page_render_time({
          :top_avg_time => [sample_output],
          :top_count => [sample_output]
       }).deliver
    end
  end

  test "new_factions_banned_user" do
    sender = User.find(1)
    recipient = User.find(2)
    fb = FactionsBannedUser.new({
        :faction_id => 1,
        :user_id => 2,
        :reason => 'más feo que el hambre',
        :banner_user_id => 1
    })
    assert_difference("ActionMailer::Base.deliveries.size") do
      NotificationEmail.new_factions_banned_user(
          'webmaster@gamersmafia.com',
          { :sender => fb.banner_user, :factions_ban => fb }).deliver
    end
  end

  test "faction_summary" do
    sender = User.find(1)
    recipient = User.find(2)
    deliveries = ActionMailer::Base.deliveries.size

    NotificationEmail.faction_summary(recipient,
                                 {:faction => Faction.find(1)}).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "invited_participant" do
    recipient = User.find(1)
    deliveries = ActionMailer::Base.deliveries.size
    NotificationEmail.invited_participant(
        recipient, {:competition => Competition.find(:first) }).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "newmessage" do
    sender = User.find(1)
    recipient = User.find(2)
    deliveries = ActionMailer::Base.deliveries.size
    nm = Message.new({:user_id_from => sender.id, :user_id_to => recipient.id, :title => 'Mensaje de prueba', :message => 'texto del mensaje de prueba', :created_on => Time.now})

    NotificationEmail.newmessage(recipient, { :sender => sender, :message => nm
        }).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "should_log_emails_sent" do
    assert_difference("SentEmail.count") do
      test_newmessage
    end
  end

  test "newprofilesignature" do
    sender = User.find(1)
    recipient = User.find(2)
    deliveries = ActionMailer::Base.deliveries.size
    NotificationEmail.newprofilesignature(recipient, { :signer => sender }).deliver
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
    deliveries = ActionMailer::Base.deliveries.size
    NotificationEmail.competition_started(
        u2, { :sender => c.admins[0], :competition => c}).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "welcome" do
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    NotificationEmail.welcome(u1).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "forgot" do
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    NotificationEmail.forgot(u1).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "signup" do
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    NotificationEmail.signup(u1).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "emailchange" do
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    NotificationEmail.emailchange(u1).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "ad_report" do
    deliveries = ActionMailer::Base.deliveries.size
    NotificationEmail.ad_report(Advertiser.find(:first), {:tstart => 1.week.ago,
        :tend => Time.now}).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "newregistration" do
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    u2 = User.find(2)
    NotificationEmail.newregistration(u1, { :refered => u2 }).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "resurrection" do
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    u2 = User.find(2)
    NotificationEmail.resurrection(u1, { :resurrected => u2 }).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end


  test "reto_aceptado" do
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
    assert_not_nil c
    p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
    NotificationEmail.reto_aceptado(u, { :participant => p }).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "reto_recibido" do
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
    assert_not_nil c
    p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
    NotificationEmail.reto_recibido(u, { :participant => p }).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "reto_pendiente_1w" do
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
    assert_not_nil c
    p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
    NotificationEmail.reto_pendiente_1w(u, { :participant => p }).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "reto_pendiente_2w" do
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
    assert_not_nil c
    p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
    NotificationEmail.reto_pendiente_2w(u, { :participant => p }).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "reto_cancelado_sin_respuesta" do
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
    assert_not_nil c
    p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
    NotificationEmail.reto_cancelado_sin_respuesta(u, { :participant => p }).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "rechallenge" do
    test_reto_recibido
    assert_difference("ActionMailer::Base.deliveries.size") do
      u = User.find(1)
      c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
      p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
      NotificationEmail.rechallenge(u, { :participant => p }).deliver
    end
  end

  test "reto_rechazado" do
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Competition.find(:first, :conditions => 'invitational is false and fee is null and competitions_participants_type_id = 1 and type = \'Ladder\'')
    assert_not_nil c
    p = CompetitionsParticipant.new({:name => 'foobakala', :competition_id => c.id})
    NotificationEmail.reto_rechazado(u, { :participant => p }).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "trackerupdate" do
    deliveries = ActionMailer::Base.deliveries.size
    u = User.find(1)
    c = Content.find(:first)
    assert_not_nil c
    NotificationEmail.trackerupdate(u, { :content => c.real_content }).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "unconfirmed_1w" do
    assert_difference("ActionMailer::Base.deliveries.size") do
      u1 = User.find(1)
      NotificationEmail.unconfirmed_1w(u1).deliver
    end
  end

  test "unconfirmed_2w" do
    assert_difference("ActionMailer::Base.deliveries.size") do
      NotificationEmail.unconfirmed_1w(User.find(1)).deliver
    end
  end

  test "newcontactar" do
    assert_difference("ActionMailer::Base.deliveries.size") do
      NotificationEmail.newcontactar(:subject => 'hola', :message => 'que tal',
          :email => 'fulanito de tal').deliver
    end
  end

  test "new_friendship_request" do
    recipient = User.find(2)
    u1 = User.find(1)
    deliveries = ActionMailer::Base.deliveries.size
    assert_difference("ActionMailer::Base.deliveries.size") do
      NotificationEmail.new_friendship_request(
          recipient,
          {:from => "#{u1.login} <#{u1.email}>",
           :invitation_key => '4d186321c1a7f0f354b297e8914ab240',
           :sender => u1}
      ).deliver
    end

    email_username = App.system_mail_user.split('@')[0]
    expected_from = "#{u1.login} <#{email_username}@gamersmafia.com>"
    last_email_str = ActionMailer::Base.deliveries.last.to_s
    assert_equal(true,
                 last_email_str.include?(expected_from),
                 last_email_str)
  end

  test "new_friendship_request_external" do
    recipient = User.find(2)
    deliveries = ActionMailer::Base.deliveries.size
    u1 = User.find(1)
    NotificationEmail.new_friendship_request_external(recipient, {:from =>
        "#{u1.login} <#{u1.email}>", :invitation_key =>
        '4d186321c1a7f0f354b297e8914ab240', :sender => u1}).deliver
    assert_equal deliveries + 1, ActionMailer::Base.deliveries.size
  end

  test "new_friendship_accepted" do
    sender = User.find(1)
    assert_difference("ActionMailer::Base.deliveries.size") do
      NotificationEmail.new_friendship_accepted(sender, { :receiver =>
          User.find(2)}).deliver
    end
  end
end
