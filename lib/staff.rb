module Staff
  def self.transition_positions
    StaffPosition.should_be_in_elections.find(:all).each do |position|
      position.open_candidacy_presentation
    end

    StaffPosition.candidacy_presentation.find(:all).each do |position|
      if position.candidacy_presentation_ends_on <= Time.now
        position.close_candidacy_presentation
      end
    end

    StaffPosition.voting.find(:all).each do |position|
      if position.voting_ends_on <= Time.now
        position.close_voting_period
      end
    end
  end

  def self.user_can_vote_staff_candidate(user, staff_candidate)
    user.id != staff_candidate.user_id
  end
end
