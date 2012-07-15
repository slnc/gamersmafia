# -*- encoding : utf-8 -*-
class PollsOption < ActiveRecord::Base
    belongs_to :poll
    has_many :polls_votes
end
