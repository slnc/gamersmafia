class StaffPosition < ActiveRecord::Base
  include AASM
  belongs_to :staff_candidate

  aasm :column => :state do
    state :unassigned, :initial => true
    state :candidacy_presentation
    state :voting
    state :elect
    state :assigned

    #event :view do
    #  transitions :to => :read, :from => [:unread]
    #end

    #event :close do
    #  transitions :to => :closed, :from => [:read, :unread]
    #end
  end
end
