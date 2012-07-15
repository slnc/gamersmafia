# -*- encoding : utf-8 -*-
class StaffCandidate < ActiveRecord::Base
  ALLOWED_POSITION_STATES_TO_DELETE = [
      StaffPosition::CANDIDACY_PRESENTATION,
      StaffPosition::VOTING,
  ]

  belongs_to :user
  belongs_to :staff_position
  has_many :staff_candidate_votes

  validates_presence_of :term_starts_on
  validates_presence_of :term_ends_on

  validates_uniqueness_of :user_id,
                          :scope => [:staff_position_id, :term_starts_on]

  before_validation :copy_term_starting_dates
  before_destroy :check_can_be_destroyed

  def key_results
    out = []
    out.append(self.key_result1) if self.key_result1.to_s != ''
    out.append(self.key_result2) if self.key_result2.to_s != ''
    out.append(self.key_result3) if self.key_result3.to_s != ''
    out
  end

  def to_s
    ("<StaffCandidate id: #{self.id}, user_id: #{self.user_id}," +
     " staff_position_id: #{self.staff_position_id}, term_starts_on:" +
     "  #{self.term_starts_on}>")
  end

  protected
  def copy_term_starting_dates
    return if self.term_starts_on
    Rails.logger.warn("copying..")
    self.term_starts_on = self.staff_position.next_term
    self.term_ends_on = self.term_starts_on.end_of_quarter
    Rails.logger.warn("term_starts_on: #{self.term_starts_on}")
  end

  def check_can_be_destroyed
    ALLOWED_POSITION_STATES_TO_DELETE.include?(self.staff_position.state)
  end
end
