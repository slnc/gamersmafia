class BanRequest < ActiveRecord::Base
  belongs_to :user
  belongs_to :banned_user, :class_name => 'User', :foreign_key => 'banned_user_id'
  belongs_to :confirming_user, :class_name => 'User', :foreign_key => 'confirming_user_id'
  
  belongs_to :unban_user, :class_name => 'User', :foreign_key => 'unban_user_id'
  belongs_to :unban_banned_user, :class_name => 'User', :foreign_key => 'unban_banned_user_id'
  belongs_to :unban_confirming_user, :class_name => 'User', :foreign_key => 'unban_confirming_user_id'
  
  before_save :check_unban_requirements
  observe_attr :unban_user_id
  
  before_create :check_not_already_pending
  
  def check_not_already_pending
    if BanRequest.count(:conditions => ['banned_user_id = ? AND confirmed_on IS NULL', self.banned_user_id]) > 0
      self.errors.add('banned_user_id', 'Ya hay un ban abierto para ese usuario.')
      false
    else
      true
    end
  end
  
  def confirm(confirming_user_id)
    raise AccessDenied unless self.confirming_user_id.nil?
    self.confirming_user_id = confirming_user_id
    self.confirmed_on = Time.now
    self.save
    bu = self.banned_user
    bu.change_internal_state('banned')
    bu.save
    Notification.deliver_yourebanned(self.banned_user, {:reason => self.reason })
    true
  end
  
  def confirm_unban(confirming_user_id)
    raise AccessDenied unless self.unban_confirming_user_id.nil?
    self.unban_confirming_user_id = confirming_user_id
    self.unban_confirmed_on = Time.now
    self.save
    bu = self.banned_user
    bu.change_internal_state('active')
    bu.save
    # Notification.deliver_youreunbanned(self.banned_user, {:reason => self.unban_reason })
    true
  end
  
  def state
    if self.unban_confirmed_on
      'desbaneado'
    elsif self.unban_confirming_user_id
      'pendiente de desbaneo'
    elsif self.confirmed_on
      'baneado'
    else
      'pendiente de baneo'
    end
  end
  
  private
  def after_create
    User.find(:all, :conditions => ['admin_permissions LIKE \'_____1%\' and id <> ?', self.user_id]).each do |u|
      Message.create({:sender_user_id => nagato.id, :recipient_user_id => u.id, :title => "Iniciado ban contra el usuario #{self.banned_user.login}", :message => "<a href=\"http://gamersmafia.com/site/slog\">Ir al log de sistema</a>"})
    end    
  end
  
  def check_unban_requirements
    if slnc_changed?(:unban_user_id)
      if self.reason_unban.to_s == ''
        self.errors.add('unban_user_id', "El campo razón del unban no puede estar en blanco")
        false
      else
        self.unban_created_on = Time.now
        true
      end
    else
      true
    end
  end
  
  validates_presence_of :user_id
  validates_presence_of :banned_user_id
  validates_presence_of :reason
end