# -*- encoding : utf-8 -*-
class SoldProfileSignatures < SoldProduct
  after_create :update_user

  def update_user
    u = self.user
    u.enable_profile_signatures = true
    u.save
    self.update_attribute(:used, true)
  end
end
