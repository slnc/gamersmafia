class CommentViolationOpinion < ActiveRecord::Base
  belongs_to :user
  belongs_to :comment

  VIOLATION = 0
  NO_VIOLATION = 1
  I_DONT_KNOW = 2

  after_create :give_retribution

  before_create :check_speed

  validates_uniqueness_of :user_id, :scope => [ :comment_id ]

  def check_speed
    if self.user.comment_violation_opinions.count(:conditions => 'created_on >= now() - \'15 seconds\'::interval') > 10
      self.errors.add('', 'no tan rápido cowboy')
      false
    else
      true
    end
  end

  def give_retribution
    Bank.transfer(:bank, self.user, 0.25, 'Enseñar a MrAchmed')
    true
  end
end
