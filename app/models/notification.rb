# -*- encoding : utf-8 -*-
class Notification < ActiveRecord::Base
  UNDEFINED = 0
  REJECTED_GMTV_CHANNEL = 1
  COUP_DETAT_INMINENT = 2
  COUP_DETAT_EXECUTED = 3
  AUTOMATIC_AB_TEST = 4
  BAN_REQUEST_INITIATED = 5
  USERS_EMBLEM_RECEIVED = 6
  USERS_SKILL_RECEIVED = 7
  CONTENT_DENIED = 8
  BEST_ANSWER_RECEIVED = 9
  OUTSTANDING_CLAN_SCHEDULED = 10
  OUTSTANDING_USER_SCHEDULED = 11
  USERS_SKILL_LOST = 12
  NICK_REFERENCE_IN_COMMENT = 13


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
  scope :with_type,
              lambda { |type_id| { :conditions => ["type_id = ?", type_id.to_s]}}

  def self.forget_old_read_notifications
    User.db_query(
        "DELETE FROM notifications
         WHERE read_on IS NOT NULL
         AND created_on >= now() - '1 month'::interval")
  end

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
