require 'aasm'

class InvalidAction < Exception; end

class StaffPosition < ActiveRecord::Base
  include AASM

  CANDIDACY_PRESENTATION = "candidacy_presentation"
  VOTING = "voting"
  UNASSIGNED = "unassigned"
  ELECT = "elect"
  ASSIGNED = "assigned"
  DISABLED = "disabled"

  DAYS_CANDIDACY_PRESENTATION = 7
  DAYS_VOTING = 7

  # Total time between a position entering candidacy_presentation and finishing
  # voting.
  TOTAL_DAYS_ELECTIONS = DAYS_CANDIDACY_PRESENTATION + DAYS_VOTING

  has_many :staff_candidates
  belongs_to :staff_candidate
  belongs_to :staff_type

  scope :should_be_in_elections,
        :conditions => [
            "state IN (?) AND term_ends_on - #{TOTAL_DAYS_ELECTIONS}::days >=" +
            " now()", [ASSIGNED, UNASSIGNED]]

  aasm :column => :state do
    state :unassigned, :initial => true
    state :candidacy_presentation
    state :voting
    state :elect
    state :assigned
    state :disabled

    event :open_candidacy_presentation do
      transitions :to => :candidacy_presentation,
                  :from => [:unassigned, :assigned]
    end

    event :close_candidacy_presentation do
      transitions :to => :voting, :from => [:candidacy_presentation]
    end

    event :close_voting_period do
      transitions :to => :elect, :from => [:voting]
      # TODO(slnc): email whoever needs to approve positions and create
      # SlogEntry
    end
  end

  def user
    User.find(self.staff_candidate.user_id)
  end

  def next_term
    if self.term_starts_on.nil?
      self.term_starts_on = Time.now.at_beginning_of_quarter
      self.term_ends_on = Time.now.at_end_of_quarter
      self.save
    end
    self.term_starts_on.at_end_of_quarter.advance(:days => 1)
  end

  def candidacy_presentation_ends_on
    if self.state != CANDIDACY_PRESENTATION
      raise InvalidAction, "Position not in candidacy_presentation state"
    end

    self.next_term.advance(
        :days => -DAYS_VOTING).to_time.end_of_day
  end

  def voting_ends_on
    if self.state != VOTING
      raise InvalidAction, "Position not in voting state"
    end

    self.next_term.advance(:days => -1).to_time.end_of_day
  end

  def current_candidates
    self.staff_candidates.find(:all, :include => :user)
  end

  def update_user_vote(user, staff_candidate)
    # TODO(slnc): pending StaffCandidateVote model
  end
end
