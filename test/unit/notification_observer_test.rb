require 'test_helper'

class NotificationObserverTest < ActiveSupport::TestCase
  test "notify on skill creation" do
    u1 = User.find(1)
    u1.users_skills.clear
    assert_difference("u1.notifications.count") do
      u1.users_skills.create(:role => "Antiflood")
    end
  end

  test "notify on question closed with no response" do
    q1 = Question.published.first
    assert_difference("q1.user.notifications.count") do
      q1.set_no_best_answer(User.first)
    end
  end

  test "notify on question closed with response" do
    question = Question.published.first
    comment = question.unique_content.comments.create({
        :user_id => 2,
        :comment => 'foo',
        :host => '127.0.0.1',
    })

    assert_difference("comment.user.notifications.count") do
      question.set_best_answer(comment.id, question.user)
    end
  end

  test "notify on BanRequest" do
    capos = UsersSkill.find_users_with_skill("Capo").size
    assert_difference("Notification.count", capos - 1) do
      ban_request = BanRequest.create({
        :user_id => 3,
        :banned_user_id => 2,
        :reason => "feo",
      })
    end
  end

  test "notify on SoldOutstandingClan" do
    u1 = User.find(1)
    sold_outstanding_clan = SoldOutstandingClan.create({
        :user_id => u1.id,
        :product_id => Product.find_by_cls('SoldOutstandingClan').id,
        :price_paid => 1,
    })
    assert_difference("u1.notifications.count") do
      sold_outstanding_clan.use({
        :portal_id => Portal.first.id,
        :clan_id => Clan.first.id,
      })
    end
  end

  test "notify on SoldOutstandingUser" do
    u1 = User.find(1)
    sold_outstanding_user = SoldOutstandingUser.create({
        :user_id => u1.id,
        :product_id => Product.find_by_cls('SoldOutstandingUser').id,
        :price_paid => 1,
    })
    assert_difference("u1.notifications.count") do
      sold_outstanding_user.use({
        :portal_id => Portal.first.id,
      })
    end
  end

  def create_comment_user_reference(comment_id, referenced_user_id)
    NeReference.create({
      :entity_id => referenced_user_id,
      :entity_class => "User",
      :referencer_class => "Comment",
      :referencer_id => comment_id,
      :referenced_on => Time.now,
    })
  end

  test "notify on ne_reference if radar enabled and pref is on" do
    u1 = User.find(1)
    sold_radar = self.buy_product(u1, SoldRadar)
    assert_difference("u1.notifications.count") do
      self.create_comment_user_reference(2, 1)
    end
  end

  test "notify on ne_reference if radar enabled and pref is off" do
    u1 = User.find(1)
    sold_radar = self.buy_product(u1, SoldRadar)
    u1.pref_radar_notifications = 0
    assert_difference("u1.notifications.count", 0) do
      self.create_comment_user_reference(2, 1)
    end
  end

  test "notify on ne_reference if radar not enabled" do
    u1 = User.find(1)
    assert_difference("u1.notifications.count", 0) do
      self.create_comment_user_reference(2, 1)
    end
  end

  test "notify on ne_reference if radar enabled and pref is on and multiple references" do
    u1 = User.find(1)
    sold_radar = self.buy_product(u1, SoldRadar)
    assert_difference("u1.notifications.count") do
      self.create_comment_user_reference(2, 1)
    end
    assert_difference("u1.notifications.count", 0) do
      self.create_comment_user_reference(2, 1)
    end
  end

end
