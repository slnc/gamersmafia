class ProfileSignature < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  belongs_to :signer, :class_name => 'User', :foreign_key => 'signer_user_id'
  
  after_create :notify_signed
  
  before_save :sanitize_signature
  validates_length_of :signature, :maximum => 400, :allow_nil => false
  
  def notify_signed
    if self.user.notifications_newprofilesignature then
      Notification.deliver_newprofilesignature(self.user, { :signer => self.signer})
    end
  end
  
  private
  def sanitize_signature
    self.signature = self.signature.gsub("\r\n", "\n")
    while self.signature.index("\n\n\n")
      self.signature = self.signature.gsub("\n\n\n", "\n")
    end
    true
  end
end