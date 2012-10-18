require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  def create_notification
    u1 = User.find(1)
    assert !u1.has_unread_notifications

    assert_difference("u1.notifications.count") do
      u1.notifications.create(:description => "Fulanito te manda un beso")
    end

    u1.reload
  end

  test "create notification should mark as unread" do
    self.create_notification
    assert u1.has_unread_notifications
  end

  test "mark_as_read works" do
    self.create_notification
    Notification.mark_as_read(
        u1, u1.notifications.find(:all).collect {|n| n.id})

    u1.reload
    assert !u1.has_unread_notifications
  end
end
