class DecisionUserChoice < ActiveRecord::Base
  belongs_to :decision
  belongs_to :decision_choice
  belongs_to :user

  before_create :populate_probability_right
  after_create :touch_decision
  after_save :try_to_decide
  scope :recent,
        :conditions => "decision_user_choices.created_on >= now() - '3 months'::interval"

  validates_presence_of :decision_choice_id
  validates_uniqueness_of :decision_choice_id, :scope => [:user_id, :decision_id]

  private
  def populate_probability_right
    self.probability_right = DecisionUserReputation.get_user_probability_for(
        self.user, self.decision.decision_type_class)
  end

  def try_to_decide
    self.decision.try_to_decide
  end

  def touch_decision
    self.decision.update_attribute(:updated_on, Time.now)
  end
end
