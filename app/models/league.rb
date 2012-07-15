# -*- encoding : utf-8 -*-
class League < Competition
  def has_options?
    true
  end

  def reset_participants_scores
    self.competitions_participants.each do |cp|
      cp.update_attributes(:points => cp.wins * 3 + cp.ties)
    end
  end
end
