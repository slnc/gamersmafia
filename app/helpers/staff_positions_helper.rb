# -*- encoding : utf-8 -*-
module StaffPositionsHelper
  def staff_position_winners(staff_position)
    winners = staff_position.staff_candidates.find(
        :all,
        :conditions => ["term_starts_on = ? AND is_winner IS TRUE",
                        staff_position.next_term],
        :include => [:user])
    winners.collect do |winner|
      link_to(winner.user.login,
              staff_position_staff_candidate_path(staff_position, winner))
    end.join(", ")
  end

  def can_confirm_staff_position_winners(user, staff_position)
    Staff.can_confirm_staff_position_winners(user, staff_position)
  end
end
