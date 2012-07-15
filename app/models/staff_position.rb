# -*- encoding : utf-8 -*-
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

  MAX_POSITION_SLOTS = 10

  SQL_CANDIDATES_VOTES = <<-END
    SELECT id,
           (SELECT COUNT (*)
              FROM staff_candidate_votes
             WHERE staff_candidate_id = staff_candidates.id) AS votes
      FROM staff_candidates
  ORDER BY votes, RANDOM()
     LIMIT #{MAX_POSITION_SLOTS}
  END

  # Total time between a position entering candidacy_presentation and finishing
  # voting.
  TOTAL_DAYS_ELECTIONS = DAYS_CANDIDACY_PRESENTATION + DAYS_VOTING

  has_many :staff_candidates
  has_many :staff_candidate_votes
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

    event :open_candidacy_presentation,
          :after => :save do
      transitions :to => :candidacy_presentation,
                  :from => [:unassigned, :assigned]
    end

    event :close_candidacy_presentation,
          :after => :save do
      transitions :to => :voting, :from => [:candidacy_presentation]
    end

    event :close_voting_period,
          :after => [:elect_winning_candidates, :save] do
      transitions :to => :elect, :from => [:voting]
      # TODO(slnc): email whoever needs to approve positions and create
      # SlogEntry
    end

    event :confirm_winners,
          :after => [:save, :update_users_roles] do
      transitions :to => :assigned, :from => [:elect]
    end
  end

  def user
    User.find(self.staff_candidate.user_id)
  end

  def update_users_roles
    # TODO(slnc): pendiente de integrar
    Rails.logger.warn("UsersRole integration is not done yet")
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
    self.staff_candidate_votes.create(
        :user_id => user.id, :staff_candidate_id => staff_candidate.id)
  end

  def to_s
    ("<StaffPosition id: #{self.id}, state: #{self.state}, term_starts_on:" +
     " #{self.term_starts_on}>")
  end

  protected
  def elect_winning_candidates
    # TODO(slnc): resolve votes
    # TODO(slnc): require minimum votes?
    candidates = User.db_query(SQL_CANDIDATES_VOTES)
    candidates.reverse!
    self.staff_candidates.find(:all).each do |candidate|
      if candidate.is_winner
        candidate.update_attributes(:is_winner => false)
        Rails.logger.warn(
          "#{candidate} had is_winner set to true. Resetting to false.")
      end
    end

    self.slots.times do |i|
      candidate_row = candidates.pop()
      candidate_model = StaffCandidate.find(candidate_row['id'].to_i)
      candidate_model.update_attributes(:is_winner => true)
      Rails.logger.info(
          "Candidate #{candidate_model} elected for #{self} with" +
          " #{candidate_row['votes']} votes.")
    end
  end
end
