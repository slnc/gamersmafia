class AllowedCompetitionsParticipant < ActiveRecord::Base
  belongs_to :competition
  after_create :send_notification
  
  def send_notification
    return if competition.state == 0
    
    if competition.competitions_participants_type_id == Competition::CLANS
      c = Clan.find(self.participant_id)
      c.admins.each { |admin| Notification.deliver_invited_participant(admin, {:competition => competition}) }
    else
      Notification.deliver_invited_participant(User.find(self.participant_id), {:competition => competition})
    end
  end
  
  def real_thing
    if self.competition.competitions_participants_type_id == Competition::USERS
      User.find(participant_id)
    else
      Clan.find(participant_id)
    end
  end
end
