class Notification < ActiveRecord::Base
  # TODO(slnc): add as many notifications from NotificationEmail as possible
  # here.
  # TODO(slnc): add ability to specify that you want to receive email for
  # notifications (per notification, per horu, per day, none).
  before_save :ensure_sender_user_id
  after_create :touch_user
  belongs_to :user
  belongs_to :sender, :class_name => 'User', :foreign_key => 'sender_user_id'

  scope :unread, :conditions => "read_on IS NULL"
  scope :read, :conditions => "read_on IS NOT NULL"

  def self.mark_as_read(user, notification_ids)
    user.notifications.find(
        :all,
        :conditions => ["id IN (?)", notification_ids]).each do |notification|
      notification.update_attribute(:read_on, Time.now)
    end
    user.update_attribute(
        :has_unread_notifications, user.notifications.unread.count > 0)
  end

  def unread?
    self.read_on.nil?
  end

  protected
  def ensure_sender_user_id
    self.sender_user_id ||= Ias.nagato.id
  end

  def touch_user
    self.user.update_attribute(:has_unread_notifications, true)
  end
end
