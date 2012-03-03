module StaffCandidatesHelper
  def user_can_vote_staff_candidate(user, staff_candidate)
    Staff.user_can_vote_staff_candidate(user, staff_candidate)
  end

  def can_create_staff_candidate(user, staff_position)
    return if staff_position.state != 'candidacy_presentation'

    staff_position.staff_candidates.count(
        :conditions => [
            'user_id = ? AND term_starts_on = ?', user.id,
            staff_position.next_term]) == 0
  end
end
