class DecisionComment < ActiveRecord::Base
  belongs_to :decision
  belongs_to :user
  before_save :truncate_long_comments

  validates_presence_of :comment, :message => 'no puede estar en blanco'

  private
  def truncate_long_comments
    self.comment = self.comment[0..5999] if self.comment.length > 6000
    true
  end
end
