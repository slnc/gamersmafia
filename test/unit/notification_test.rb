require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  def create_notification
    notif = @u1.notifications.new({
        :description => "Fulanito te manda un beso",
        :type_id => Notification::UNDEFINED,
    })
    assert_difference("@u1.notifications.count") do
      notif.save
    end
    @u1.reload
    notif
  end

  test "create notification should mark as unread" do
    @u1 = User.find(1)
    assert !@u1.has_unread_notifications
    self.create_notification
    assert @u1.has_unread_notifications
  end

  test "mark_as_read works" do
    @u1 = User.find(1)
    assert !@u1.has_unread_notifications
    self.create_notification
    Notification.mark_as_read(
        @u1, @u1.notifications.unread.find(:all).collect {|n| n.id})
    assert !@u1.has_unread_notifications
  end

  test "forget_old_read_notifications" do
    @u1 = User.find(1)
    notification1 = self.create_notification
    notification2 = self.create_notification
    notification2.update_column(:created_on, 2.months.ago)
    Notification.forget_old_read_notifications
    Notification.mark_as_read(
        @u1, @u1.notifications.unread.find(:all).collect {|n| n.id})
    @u1.reload
    assert_difference("@u1.notifications.count", -1) do
      Notification.forget_old_read_notifications
    end
  end
end
