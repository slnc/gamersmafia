class PollsVote < ActiveRecord::Base
    belongs_to :polls_option, :counter_cache => true
    belongs_to :user

    after_create :update_polls_total
    after_destroy :update_polls_total

    private
    def update_polls_total
      self.polls_option.poll.recalculate_polls_votes_count
    end
end
