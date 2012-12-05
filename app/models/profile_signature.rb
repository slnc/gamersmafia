# -*- encoding : utf-8 -*-
class ProfileSignature < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  belongs_to :signer, :class_name => 'User', :foreign_key => 'signer_user_id'

  after_create :notify_signed
  after_create :update_last_profile_signature
  after_destroy :update_last_profile_signature

  before_save :sanitize_signature
  validates_length_of :signature, :maximum => 400, :allow_nil => false

  def notify_signed
    if self.user.notifications_newprofilesignature then
      NotificationEmail.newprofilesignature(
          self.user, {:signer => self.signer}).deliver
    end
  end

  private
  def update_last_profile_signature
    last_sig = ProfileSignature.last
    Keystore.set(
        "timestamps.last_profile_signature", last_sig ? last_sig.created_on : 0)
  end

  def sanitize_signature
    self.signature = self.signature.gsub("\r\n", "\n")
    while self.signature.index("\n\n\n")
      self.signature = self.signature.gsub("\n\n\n", "\n")
    end
    true
  end
end
