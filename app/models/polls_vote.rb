class PollsVote < ActiveRecord::Base
    belongs_to :polls_option, :counter_cache => true
    belongs_to :user
end
