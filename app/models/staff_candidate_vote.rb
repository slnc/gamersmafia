class StaffCandidateVote < ActiveRecord::Base
  belongs_to :user
  belongs_to :staff_candidate
  belongs_to :staff_position

  before_create :delete_other_votes

  protected
  def delete_other_votes
    # Delete all votes for staff candidates for the same term
  candidate_ids = StaffCandidate.find(
        :all,
        :conditions => [
            'staff_position_id = ? AND term_starts_on = ?',
            self.staff_position_id,
            self.staff_candidate.term_starts_on]).collect do |candidate|
      candidate.id
    end
    StaffCandidateVote.destroy_all(
        ["staff_candidate_id IN (?) AND user_id = ?", candidate_ids,
        self.user_id])
  end
end
