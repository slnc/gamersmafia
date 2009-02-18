class GlobalNotification < ActiveRecord::Base
  validates_presence_of :title
  validates_presence_of :main
  validates_presence_of :recipient_type
  observe_attr :confirmed
  VALID_RECIPIENT_TYPES = [:global, :clanleaders, :gmtv_owners]
  
  before_save :check_no_flood
  
  def completedness
    SentEmail.count(:conditions => ['global_notification_id = ?', self.id]).to_f / User.count(:conditions => sql_user_conditions).to_f 
  end
  
  def sql_user_conditions(start_after_user_id=nil)
    # devuelve la condición sql que seleccione los users a los que enviar la notificación
    base = "state IN (#{User::STATES_CAN_LOGIN.join(',')})"
    
    if self.recipient_type.to_s == 'gmtv_owners'
      base << " AND notifications_global = 't' AND id IN (SELECT user_id FROM gmtv_channels)"
    else
      base << " AND notifications_#{self.recipient_type} = 't'"
    end
    
    base << " AND id > #{start_after_user_id}" if start_after_user_id
    base << " AND id = 1" unless App.enable_global_notifications?
    base
  end
  
  def check_completedness
    if User.count(:conditions => sql_user_conditions) == 0
      self.completed_on = Time.now
      self.save
    end
  end
  
  def check_no_flood
    if self.slnc_changed?(:confirmed) && self.confirmed == true
      GlobalNotification.count(:conditions => ["created_on > now() - '1 month'::interval AND confirmed = 't' 
                                            AND recipient_type = ?", self.recipient_type]) == 0
    else
      true
    end
  end
  
  def recipients_count
    SentEmail.count(:conditions => ["global_notification_id = ?", self.id])
  end
  
  def confirmed_readings
    SentEmail.count(:conditions => ["first_read_on is not null and global_notification_id = ?", self.id]).to_f / recipients_count.to_f
  end
end
