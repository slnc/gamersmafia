class StaffCandidate < ActiveRecord::Base
  belongs_to :user
  belongs_to :staff_position
  has_many :staff_candidate_votes

  def key_results
    out = []
    out.append(self.key_result1 if self.key_result1)
    out.append(self.key_result2 if self.key_result2)
    out.append(self.key_result3 if self.key_result3)
    out
  end
end
