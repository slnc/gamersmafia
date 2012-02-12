class AmmountTooLow < Exception; end

class BetsTicket < ActiveRecord::Base
  MIN_BET = 5.0
  belongs_to :user
  belongs_to :bets_option

  has_bank_ammount_from_user

  def after_ammount_update
    if self.ammount_changed?
      bo = BetsOption.find(self.bets_option_id)
      bo.ammount ||= 0
      bet = bo.bet
      bet.total_ammount ||= 0
      bo.ammount += self.ammount - self.ammount_was
      bet.total_ammount += self.ammount - self.ammount_was
      bo.save
      bet.save
    end
    true
  end

  def ammount_owner
    self.user
  end

  def ammount_increase_message
    "Aumentas tu apuesta por #{self.bets_option.name} en \"#{self.bets_option.bet.resolve_hid}\""
  end

  def ammount_decrease_message
    "Reduces tu apuesta por #{self.bets_option.name} en \"#{self.bets_option.bet.resolve_hid}\""
  end

  def ammount_returned
    "Opción #{self.bets_option.name} eliminada de la apuesta #{self.bets_option.bet.title}"
  end

  def ammount_increase_checks(diff, new_ammount)
    raise AmmountTooLow if new_ammount != 0 && new_ammount < MIN_BET
    if diff < 0 && self.created_on.to_i <= (Time.now.to_i - 15 * 60)
      raise TooLateToLower
    end
  end
end
