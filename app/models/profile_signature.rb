class ProfileSignature < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  belongs_to :signer, :class_name => 'User', :foreign_key => 'signer_user_id'
  
  after_create :notify_signed

  def notify_signed
    if self.user.notifications_newprofilesignature then
      Notification.deliver_newprofilesignature(self.user, { :signer => self.signer})
    end
  end
end