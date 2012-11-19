# -*- encoding : utf-8 -*-
class DecisionComment < ActiveRecord::Base
  belongs_to :decision
  belongs_to :user
  before_save :truncate_long_comments
  after_save :touch_decision
  after_create :schedule_notification_initiating_user_id

  validates_presence_of :comment, :message => 'no puede estar en blanco'

  private
  def truncate_long_comments
    self.comment = self.comment[0..5999] if self.comment.length > 6000
    true
  end

  def touch_decision
    self.decision.touch
  end

  def schedule_notification_initiating_user_id
    if self.decision.context[:initiating_user_id]
      Notification.create({
          :type_id => Notification::DECISION_COMMENT,
          :sender_user_id => self.user_id,
          :description => (
              "<a href=\"#{Routing.gmurl(self.user)}\">#{self.user.login}</a>
              ha comentado \"#{self.comment}\" en una decisión que te concierne
              (<a href=\"/decisiones/#{self.decision_id}\"><strong>#{self.decision.decision_description}</strong></a>)."),
          :user_id => self.decision.context[:initiating_user_id],
      })
    end
  end
end
