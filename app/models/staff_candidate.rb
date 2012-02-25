class StaffCandidate < ActiveRecord::Base
  belongs_to :user
  belongs_to :staff_position
end
