# -*- encoding : utf-8 -*-
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

  def can_deny_staff_candidate(user, staff_position, staff_candidate)
    Staff.can_deny_staff_candidate(user, staff_position, staff_candidate)
  end

  def can_edit_staff_candidate(user, staff_position, staff_candidate)
    Staff.can_edit_staff_candidate(user, staff_position, staff_candidate)
  end

  def staff_candidate_state(staff_candidate)
    staff_position = staff_candidate.staff_position
    if staff_position.state == StaffPosition::CANDIDACY_PRESENTATION
      "Presentación de candidaturas"
    elsif staff_position.state == StaffPosition::VOTING
      "Votación"
    elsif staff_position.state == StaffPosition::ELECT
      if staff_candidate.is_winner
        "Electo"
      else
        "No electo"
      end
    else
      "Elecciones finalizadas"
    end
  end
end
