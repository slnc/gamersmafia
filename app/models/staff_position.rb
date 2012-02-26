require 'aasm'

class StaffPosition < ActiveRecord::Base
  include AASM

  has_many :staff_candidates
  belongs_to :staff_candidate
  belongs_to :staff_type

  aasm :column => :state do
    state :unassigned, :initial => true
    state :candidacy_presentation
    state :voting
    state :elect
    state :assigned

    #event :view do
    #  transitions :to => :read, :from => [:unread]
    #end

    event :open_candidacy_presentation do
      transitions :to => :candidacy_presentation, :from => [:unassigned]
    end

    #event :close do
    #  transitions :to => :closed, :from => [:read, :unread]
    #end

    def user
      User.find(self.staff_candidate.user_id)
    end
  end
end
