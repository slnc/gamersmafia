class DecisionComment < ActiveRecord::Base
  belongs_to :decision
  belongs_to :user
  before_save :truncate_long_comments
  after_save :touch_decision

  validates_presence_of :comment, :message => 'no puede estar en blanco'

  private
  def truncate_long_comments
    self.comment = self.comment[0..5999] if self.comment.length > 6000
    true
  end

  def touch_decision
    self.decision.touch
  end
end
