class StaffCandidate < ActiveRecord::Base
  belongs_to :user
  belongs_to :staff_position
  has_many :staff_candidate_votes
end
