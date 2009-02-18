class PollsOption < ActiveRecord::Base
    belongs_to :poll
    has_many :polls_votes
    acts_as_list :scope => :poll_id
end
